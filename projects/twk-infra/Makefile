check:
	@test -n "$$AWS_ACCESS_KEY" && test -n "$$AWS_SECRET_KEY" || (echo "credentials not loaded" && exit 1)

init: check
	terraform init

plan: check
	terraform plan -input=false -out=tfplan

apply: check
	terraform apply -input=false tfplan