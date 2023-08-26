package main

import (
	"bufio"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/ulikunitz/xz"
)

func main() {
	base := os.Args[1]
	target := os.Args[2]

	basePackages := processFile(base)
	targetPackages := processFile(target)

	compare(basePackages, targetPackages)
}

func processFile(url string) map[string]string {

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

	packages := make(map[string]string)
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
				} else {
					currentPackage = ""
				}
			}
		} else {
			if strings.HasPrefix(line, "Version: ") && currentPackage != "" {
				packages[currentPackage] = strings.TrimPrefix(line, "Version: ")
			}
		}
	}
	return packages

}

func compare(basePackages map[string]string, targetPackages map[string]string) {
	for pack, version := range targetPackages {
		if baseVersion, ok := basePackages[pack]; ok {
			if baseVersion != version {
				os.Stdout.WriteString(pack)
			}
		} else {
			os.Stdout.WriteString(pack)
		}
	}
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
}
