#!/bin/bash

source config/harbor-config.env

echo "🔍 Verifying Argo CD Image Updater setup..."

# 1. Image Updater 상태 확인
echo "📦 Checking Image Updater deployment..."
kubectl get deployment argocd-image-updater -n ${ARGOCD_NAMESPACE}

# 2. Secret 확인
echo "🔐 Checking secrets..."
kubectl get secret harbor-credentials -n ${ARGOCD_NAMESPACE}
kubectl get secret harbor-pull-secret -n ${BACKEND_NAMESPACE}

# 3. ConfigMap 확인
echo "⚙️ Checking registries configuration..."
kubectl get configmap argocd-image-updater-config -n ${ARGOCD_NAMESPACE} -o yaml

# 4. Application 상태 확인
echo "🚢 Checking Argo CD Application..."
kubectl get application backend-app -n ${ARGOCD_NAMESPACE}

# 5. 백엔드 파드 상태 확인
echo "🏃 Checking backend pods..."
kubectl get pods -n ${BACKEND_NAMESPACE}

# 6. Image Updater 로그 미리보기
echo "📝 Image Updater recent logs:"
kubectl logs --tail=10 deployment/argocd-image-updater -n ${ARGOCD_NAMESPACE}

echo ""
echo "✅ Verification completed!"
