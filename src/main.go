package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync"

	"github.com/klauspost/compress/gzip"

	"github.com/ulikunitz/xz"
	"pault.ag/go/debian/version"
)

func main() {
	if os.Args[1] == "sign" {
		signFiles(os.Args[2])
		return
	}

	if os.Args[1] == "repoadd" {
		repoAdd(os.Args[2], os.Args[3])
		return
	}

	config := config{
		Source:   os.Args[1],
		Target:   os.Args[2],
		Download: false,
	}

	if len(os.Args) > 3 {
		config.Download = true
		config.DlUrl = os.Args[3]
		config.Output = os.Args[4]
	}

	basePackages := processFile(config.Source)
	targetPackages := processFile(config.Target)

	changed := compare(basePackages, targetPackages, config.Download)
	if config.Download {
		download(changed, config.DlUrl, config.Output)
	}
}

func processFile(url string) map[string]packageInfo {

	resp, err := http.Get(url)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	rdr := io.Reader(resp.Body)
	if strings.HasSuffix(url, ".xz") {
		r, err := xz.NewReader(resp.Body)
		if err != nil {
			log.Fatalf("xz error %s", err)
		}
		rdr = r
	}
	if strings.HasSuffix(url, ".gz") {
		r, err := gzip.NewReader(resp.Body)
		if err != nil {
			log.Fatalf("gzip error %s", err)
		}
		rdr = r
	}

	packages := make(map[string]packageInfo)
	var currentPackage string
	scanner := bufio.NewScanner(rdr)
	for scanner.Scan() {
		line := scanner.Text()

		if line == "" {
			currentPackage = ""
		}

		if currentPackage == "" {
			if strings.HasPrefix(line, "Package: ") {
				pkName := strings.TrimPrefix(line, "Package: ") + " "
				_, broken := brokenPackages[pkName]
				if !broken {
					currentPackage = pkName
					packages[currentPackage] = packageInfo{
						Name: pkName,
					}
				} else {
					currentPackage = ""
				}
			}
		} else {
			if strings.HasPrefix(line, "Version: ") {
				ver, err := version.Parse(strings.TrimPrefix(line, "Version: "))
				if err != nil {
					panic(err)
				}
				packages[currentPackage] = packageInfo{
					Name:    currentPackage,
					Version: ver,
				}
			}
			if strings.HasPrefix(line, "Filename: ") {
				packages[currentPackage] = packageInfo{
					Name:     currentPackage,
					Version:  packages[currentPackage].Version,
					FilePath: strings.TrimPrefix(line, "Filename: "),
				}
			}
		}
	}
	return packages
}

func compare(basePackages map[string]packageInfo, targetPackages map[string]packageInfo, download bool) map[string]packageInfo {
	output := make(map[string]packageInfo)
	for pack, info := range targetPackages {
		if baseVersion, ok := basePackages[pack]; ok {
			if version.Compare(info.Version, baseVersion.Version) > 0 {
				output[pack] = info
				if !download {
					os.Stdout.WriteString(pack)
				}
			}
		} else {
			output[pack] = info
			if !download {
				os.Stdout.WriteString(pack)
			}
		}
	}
	return output
}

func repoAdd(path string, args string) {

	dir, err := os.Open(path)
	if err != nil {
		panic(err)
	}
	defer dir.Close()

	files, err := dir.Readdirnames(-1)
	if err != nil {
		panic(err)
	}

	count := 500
	totalCount := len(files)
	filePaths := ""
	for _, file := range files {
		if count > 0 && totalCount > 0 && strings.HasSuffix(file, ".deb") {
			count--
			totalCount--
			filePaths = filePaths + " " + path + file
		} else if filePaths != "" {
			count = 500
			cmd := exec.Command("/bin/bash", "-c", "reprepro "+args+" "+filePaths)
			out, err := cmd.CombinedOutput()
			if err != nil {
				panic(string(out))
			}
			fmt.Printf(string(out))
			filePaths = ""
		}
	}
}

func signFiles(path string) {

	dir, err := os.Open(path)
	if err != nil {
		panic(err)
	}
	defer dir.Close()

	files, err := dir.Readdirnames(-1)
	if err != nil {
		panic(err)
	}

	signQueue := make(chan string, 10)
	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case path, ok := <-signQueue:
					if !ok {
						return
					}
					ch := make(chan bool)
					go func() {
						sign(ch, path)
					}()
					<-ch
				default:
					// No more files to sign, exit the goroutine
					return
				}
			}
		}()
	}

	for _, file := range files {
		signQueue <- path + file
	}

	close(signQueue)

	wg.Wait()
}

func sign(ch chan bool, path string) {
	if strings.HasSuffix(path, ".deb") {
		fmt.Printf("Signing %s \n", path)
		cmd := exec.Command("/bin/bash", "-c", "dpkg-sig", "--sign", "builder", path)
		out, err := cmd.CombinedOutput()
		if err != nil {
			panic(string(out))
		}
	}
	ch <- true
}

func download(packages map[string]packageInfo, url string, output string) {
	// Create a buffered channel to store the packages to be downloaded
	packageQueue := make(chan packageInfo, 24)

	// Create a worker pool with 10 workers
	var wg sync.WaitGroup
	for i := 0; i < 24; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case pack, ok := <-packageQueue:
					if !ok {
						return
					}
					fmt.Printf("Downloading %s \n", pack.Name)
					resp, err := http.Get(url + pack.FilePath)
					if err != nil {
						fmt.Printf("Failed to download %s: %v \n", pack.Name, err)
						continue
					}
					defer resp.Body.Close()
					rdr := io.Reader(resp.Body)
					path := output + strings.Split(pack.FilePath, "/")[len(strings.Split(pack.FilePath, "/"))-1]
					file, err := os.Create(path)
					if err != nil {
						fmt.Printf("Failed to create file %s: %v \n", path, err)
						continue
					}
					defer file.Close()
					_, err = io.Copy(file, rdr)
					if err != nil {
						fmt.Printf("Failed to save file %s: %v \n", path, err)
						continue
					}
				default:
					// No more packages to download, exit the goroutine
					return
				}
			}
		}()
	}

	// Add the packages to the queue
	for _, pack := range packages {
		packageQueue <- pack
	}

	// Close the queue to signal the workers to stop
	close(packageQueue)

	// Wait for all the workers to finish
	wg.Wait()
}

type config struct {
	Source   string
	Target   string
	Download bool
	DlUrl    string
	Output   string
}

type packageInfo struct {
	Name     string
	Version  version.Version
	FilePath string
}

var brokenPackages = map[string]bool{
	"libkpim5mbox-data ":               true,
	"libkpim5identitymanagement-data ": true,
	"libkpim5libkdepim-data ":          true,
	"libkpim5imap-data ":               true,
	"libkpim5ldap-data ":               true,
	"libkpim5mailimporter-data ":       true,
	"libkpim5mailtransport-data ":      true,
	"libkpim5akonadimime-data ":        true,
	"libkpim5kontactinterface-data ":   true,
	"libkpim5ksieve-data ":             true,
	"libkpim5textedit-data ":           true,
	"libk3b-data ":                     true,
	"libkpim5eventviews-data ":         true,
	"libkpim5incidenceeditor-data ":    true,
	"libkpim5calendarsupport-data ":    true,
	"libkpim5calendarutils-data ":      true,
	"libkpim5grantleetheme-data ":      true,
	"libkpim5pkpass-data ":             true,
	"libkpim5gapi-data ":               true,
	"libkpim5akonadisearch-data ":      true,
	"libkpim5gravatar-data ":           true,
	"libkpim5akonadicontact-data ":     true,
	"libkpim5akonadinotes-data ":       true,
	"libkpim5libkleo-data ":            true,
	"plasma-mobile-tweaks ":            true,
	"libkpim5mime-data ":               true,
	"libkf5textaddons-data ":           true,
	"libkpim5smtp-data ":               true,
	"libkpim5tnef-data ":               true,
	"libkpim5akonadicalendar-data ":    true,
	"libkpim5akonadi-data ":            true,
	"libnvidia-common-390 ":            true,
	"libnvidia-common-530 ":            true,
	"midisport-firmware ":              true,
}
