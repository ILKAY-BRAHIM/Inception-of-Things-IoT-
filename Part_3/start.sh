#forward svc argocd localy...
kubectl port-forward svc/argocd-server -n argocd 8080:443
# get init password in cli argo or in secret in kube
argocd admin initial-password -n argocd || kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
ARGOCD_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $1}')
#login in argocd 
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web
#sewitch to argocd namespace
kubectl config set-context --current --namespace=argocd
# Create a directory app
argocd app create app --repo https://github.com/ILKAY-BRAHIM/Inception-of-Things-IoT-.git --path 'Part_3/simple_app' --dest-namespace dev --dest-server https://kubernetes.default.svc --grpc-web
#protect this script from running while will app already exists
#....
#View created app before sync and configuration
argocd app get app --grpc-web
#Sync the app and configure for automated synchronization
argocd app sync app --grpc-web
#??
argocd app set app --sync-policy automated --grpc-web
#if empty repo in github enabling auto prune to remove all in argocd
argocd app set app --auto-prune --allow-empty --grpc-web