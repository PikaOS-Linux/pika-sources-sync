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
				currentPackage = strings.TrimPrefix(line, "Package: ")
			}
		} else {
			if strings.HasPrefix(line, "Version: ") {
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
				println(pack)
			}
		} else {
			println(pack)
		}
	}
}
