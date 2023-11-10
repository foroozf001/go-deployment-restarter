package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"

	"github.com/foroozf001/go-deployment-restarter/internal/logging"
)

const wait time.Duration = 2 * time.Second

func main() {
	logger := logging.DefaultLogger()
	customError := errors.New("missing variable")

	podNamespace, ok := os.LookupEnv("NAMESPACE")
	if !ok {
		logger.Err(customError).Msg("NAMESPACE")
		panic(customError.Error())
	}

	deploymentName, ok := os.LookupEnv("DEPLOYMENT")
	if !ok {
		logger.Err(customError).Msg("DEPLOYMENT")
		panic(customError.Error())
	}

	config, err := rest.InClusterConfig()
	if err != nil {
		logger.Err(err).Msg("in-cluster config")
		panic(err.Error())
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		logger.Err(err).Msg("clientset")
		panic(err.Error())
	}

	deploymentsClient := clientset.AppsV1().Deployments(podNamespace)
	// patch restartedAt annotation to trigger a rollout restart
	patch := fmt.Sprintf(`{"spec": {"template": {"metadata": {"annotations": {"kubectl.kubernetes.io/restartedAt": "%s"}}}}}`, time.Now().Format(time.RFC3339))
	_, err = deploymentsClient.Patch(context.TODO(), deploymentName, types.StrategicMergePatchType, []byte(patch), metav1.PatchOptions{})
	if err != nil {
		logger.Err(err).Msg("patching")
		panic(err.Error())
	}

	deployment, err := deploymentsClient.Get(context.TODO(), deploymentName, metav1.GetOptions{})
	if err != nil {
		logger.Err(err).Msg("deployment")
		panic(err.Error())
	}

	replicas := deployment.Spec.Replicas
	// match the pods by means of deployment label selectors
	labelSelector := metav1.LabelSelector{MatchLabels: deployment.GetLabels()}
	listOptions := metav1.ListOptions{
		LabelSelector: labels.Set(labelSelector.MatchLabels).String(),
	}

	for {
		// list pods matching deployment labels
		pods, err := clientset.CoreV1().Pods(podNamespace).List(context.TODO(), listOptions)
		if err != nil {
			logger.Err(err).Msg("pods")
			panic(err.Error())
		}

		if len(pods.Items) == int(*replicas) {
			logger.Info().Msg(fmt.Sprintf("deployment \x22%s\x22 successfully rolled out", deploymentName))
			break
		}

		logger.Info().Msg(fmt.Sprintf("Waiting for deployment \x22%s\x22 rollout to finish...", deploymentName))

		time.Sleep(wait)
	}
}
