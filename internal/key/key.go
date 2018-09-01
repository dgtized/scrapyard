package key

import (
	"crypto/sha1"
	"fmt"
	"github.com/sirupsen/logrus"
	"io/ioutil"
	"path/filepath"
	"regexp"
	"strings"
)

var interpolater = regexp.MustCompile(`#\([^}]+\)`)

// checksum interpolates a template string with the checksums of files
//
// For example, `checksum("foo-#(main.go)")` would interpolate the checksum of
// the contents of `main.go` to make something like `"foo-123abc654"`.
func checksum(key string, log logrus.FieldLogger) string {
	return interpolater.ReplaceAllStringFunc(key, func(m string) string {
		match := strings.TrimSpace(m[2 : len(m)-1])
		matchLog := log.WithField("match", match)

		bytes, err := ioutil.ReadFile(match)
		if err != nil {
			matchLog.Debug("File does not exist, ignoring checksum")
			return ""
		}
		matchLog.Debug("Including sha1 of file")
		hash := sha1.New()
		hash.Write(bytes)
		return fmt.Sprintf("%x", hash.Sum(nil))
	})
}

// ToPath converts a Key into a file path by interpolating any checksums.
func ToPath(yard, key, extension string, log logrus.FieldLogger) string {
	return filepath.Join(yard, checksum(key, log)+extension)
}
