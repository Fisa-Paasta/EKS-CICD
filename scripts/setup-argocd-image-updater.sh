#!/bin/bash

# 설정 파일 로드
source config/harbor-config.env

echo "🚀 Setting up Argo CD Image Updater for Harbor integration..."

# 1. Image Updater 설치
echo "📦 Installing Argo CD Image Updater..."
kubectl apply -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

# 설치 완료 대기
echo "⏳ Waiting for Image Updater to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-image-updater -n ${ARGOCD_NAMESPACE}

# 2. Harbor 인증 Secret 생성
echo "🔐 Creating Harbor credentials secret..."
kubectl create secret generic harbor-credentials \
  --from-literal=username=${HARBOR_USERNAME} \
  --from-literal=password=${HARBOR_PASSWORD} \
  -n ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 3. Harbor 레지스트리 설정
echo "⚙️ Configuring Harbor registry..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: ${ARGOCD_NAMESPACE}
data:
  registries.conf: |
    registries:
    - name: harbor
      api_url: https://${HARBOR_URL}/api
      credentials: secret:${ARGOCD_NAMESPACE}/harbor-credentials
      default: true
EOF

# 4. 백엔드 네임스페이스 생성
echo "📂 Creating backend namespace..."
kubectl create namespace ${BACKEND_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 5. Harbor Pull Secret 생성
echo "🔑 Creating Harbor pull secret for backend namespace..."
kubectl create secret docker-registry harbor-pull-secret \
  --docker-server=${HARBOR_URL} \
  --docker-username=${HARBOR_USERNAME} \
  --docker-password=${HARBOR_PASSWORD} \
  --docker-email=devops@company.com \
  -n ${BACKEND_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 6. Image Updater 재시작
echo "🔄 Restarting Image Updater to apply new configuration..."
kubectl rollout restart deployment/argocd-image-updater -n ${ARGOCD_NAMESPACE}

# 7. Application 배포
echo "🚢 Deploying Argo CD Application..."
kubectl apply -f argocd/backend-app.yaml

echo "✅ Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Check Image Updater logs: kubectl logs -f deployment/argocd-image-updater -n ${ARGOCD_NAMESPACE}"
echo "2. Access Argo CD UI: kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
echo "3. Push new image to Harbor and watch for automatic updates!"
