package pack

import (
	"github.com/sirupsen/logrus"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
)

// Restore the files in a tarball.
func Restore(log logrus.FieldLogger, cache string, paths []string) error {
	duCommand := exec.Command("du", "-sh", strings.Join(paths, " "))
	tarCommand := exec.Command("tar", "zxf", cache)
	restoreLog := log.WithFields(
		logrus.Fields{
			"cache":      cache,
			"duCommand":  duCommand.Args,
			"paths":      paths,
			"tarCommand": tarCommand.Args,
		},
	)

	restoreLog.Debug("Found scrap in cache")
	restoreLog.Info("Executing tar command")
	if err := tarCommand.Run(); err != nil {
		return err
	}
	if len(paths) > 0 {
		duOutput, err := duCommand.Output()
		if err != nil {
			return err
		}
		restoreLog.
			WithField("duOutput", strings.TrimSpace(string(duOutput))).
			Info("Restored cache")
	}
	return nil
}

// Save the paths in the given tarball name.
func Save(log logrus.FieldLogger, cache string, paths []string) error {
	file, errTemp := ioutil.TempFile("", "scrapyard")
	if errTemp != nil {
		return errTemp
	}
	fileName := file.Name()
	defer os.Remove(fileName)

	lsCommand := exec.Command("ls", "-lah", cache)
	mvCommand := exec.Command("mv", fileName, cache)
	tarCommand := exec.Command("tar", append([]string{"czf", fileName}, paths...)...)
	touchCommand := exec.Command("touch", cache)
	saveLog := log.WithFields(
		logrus.Fields{
			"cache":        cache,
			"tarCommand":   tarCommand.Args,
			"tempFile":     fileName,
			"touchCommand": touchCommand.Args,
		},
	)

	saveLog.Debug("Executing tar command")
	if err := tarCommand.Run(); err != nil {
		return err
	}
	if err := mvCommand.Run(); err != nil {
		return err
	}
	if err := touchCommand.Run(); err != nil {
		return err
	}
	lsOutput, err := lsCommand.Output()
	if err != nil {
		return err
	}

	saveLog.
		WithField("lsOutput", strings.TrimSpace(string(lsOutput))).
		Info("Created cache")
	return nil
}
