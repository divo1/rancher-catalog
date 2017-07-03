package main

import (
	"time"
	"crypto/md5"
	"encoding/hex"
	"strings"
)

type Backup struct {
	name string
	rootDir string
	relativeDir string
	dateDir string
	ext string
}

func NewBackup() (*Backup, error) {
	Info.Print("Creating backup object")
	t := time.Now()
	backup := new(Backup)
	backup.name = t.Format("15.04.05.999999")
	backup.rootDir = "/backup/"
	backup.dateDir = t.Format("2006/01/02/")
	backup.ext = "tar.bz2"

	return backup, nil
}

func GetMD5Hash(text string) string {
	hasher := md5.New()
	hasher.Write([]byte(text))
	return hex.EncodeToString(hasher.Sum(nil))
}

func (b Backup) getDirName(name string, path string) string {
	return strings.Replace(name, "\\", "-", -1) + "/" + GetMD5Hash(path) + "/"
}

func (b Backup) getFileNameWithExt() string {
	return b.name + "." + b.ext
}

func (b Backup) getCmd(containerName string, src string, dest string) string {
	dir := b.getDirName(containerName, src)
	datePath := b.dateDir
	backupFileName := b.getFileNameWithExt()
	
	backupFilePath := b.rootDir + dir + datePath
	hostFilePath := dest + dir + datePath + backupFileName

	Info.Print("Backup file path: ", backupFilePath)
	Info.Print("Host file path: ", hostFilePath)

	commandBuf := []string {
		"mkdir -p " + backupFilePath,
		"cd " + src,
		"tar cvf " + backupFilePath + backupFileName + " -g " + backupFilePath + "snapshot.incr " + "*",
		"cd " + b.rootDir + dir,
		"ln -sf " + hostFilePath + " latest." + b.ext,
	}
	
	cmd := strings.Join(commandBuf," && ")

	Info.Print("Command: ", cmd)
	return cmd
}

func (b Backup) getDockerConfigToStore(containerName string, src string, dest string) DockerConfig {
	Info.Print("Store: ", containerName, src, dest)
	return DockerConfig{
		cmd: b.getCmd(containerName, src, dest),
		VolumesFrom: []string{containerName},
		Binds: []string{dest + ":" + b.rootDir},
	}
}