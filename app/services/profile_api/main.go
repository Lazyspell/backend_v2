package main

import (
	"fmt"
	"os"
	"os/signal"
	"runtime"
	"syscall"

	"github.com/jelam2474/backend_v2/foundation/logger"
	"go.uber.org/zap"
)

var build = "develop"

func main() {
	log, err := logger.New("PROFILE-API")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer log.Sync()

	if err := run(log); err != nil {
		log.Errorw("startup", "ERROR", err)
		log.Sync()
		os.Exit(1)
	}
}

func run(log *zap.SugaredLogger) error {

	// ==============================================================================
	// GOMAXPROCS

	log.Infow("startup", "GOMAXPROCS", runtime.GOMAXPROCS(0))
	defer log.Infow("shdudown")

	shudown := make(chan os.Signal, 1)
	signal.Notify(shudown, syscall.SIGINT, syscall.SIGABRT)
	<-shudown

	return nil

}
