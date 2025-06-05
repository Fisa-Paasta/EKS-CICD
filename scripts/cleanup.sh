#!/bin/bash

source config/harbor-config.env

echo "🧹 Cleaning up Argo CD Image Updater setup..."

# Application 삭제
kubectl delete application backend-app -n ${ARGOCD_NAMESPACE} --ignore-not-found=true

# 백엔드 리소스 삭제
kubectl delete namespace ${BACKEND_NAMESPACE} --ignore-not-found=true

# Argo CD 네임스페이스의 설정 삭제
kubectl delete secret harbor-credentials -n ${ARGOCD_NAMESPACE} --ignore-not-found=true
kubectl delete configmap argocd-image-updater-config -n ${ARGOCD_NAMESPACE} --ignore-not-found=true

# Image Updater 삭제
kubectl delete -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml --ignore-not-found=true

echo "✅ Cleanup completed!"
