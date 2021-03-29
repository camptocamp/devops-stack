MODULES = argocd-helm aks/azure eks/aws openshift4/aws k3s/docker k3s/libvirt
MOD_REFS = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/terraform_modules/,$(MODULES)))

APPLICATIONS = $(shell ls argocd)
APP_REFS = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/applications/,$(APPLICATIONS)))

mod_refs: $(MOD_REFS)

docs/modules/ROOT/pages/references/terraform_modules/%.adoc:
	mkdir -p $(shell dirname $@)
	terraform-docs asciidoc --header-from README.adoc modules/$* > $@

app_refs: $(APP_REFS)

docs/modules/ROOT/pages/references/applications/%.adoc:
	cat argocd/$*/README.md argocd/$*/REFERENCE.md | pandoc -o $@

argocd/%/README.md: helm-docs

helm-docs:
	helm-docs -o REFERENCE.md
