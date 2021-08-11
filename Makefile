MODULES = argocd-helm aks/azure eks/aws openshift4/aws k3s/docker k3s/libvirt sks/exoscale
MOD_REFS = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/terraform_modules/,$(MODULES)))

APPLICATIONS = $(shell ls -d argocd/*/ | cut -f2 -d'/')
APP_REFS = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/applications/,$(APPLICATIONS)))

refs: mod_refs app_refs
clean_refs: clean_mod_refs clean_app_refs

mod_refs: $(MOD_REFS)
clean_mod_refs:
	rm -f $(MOD_REFS)

docs/modules/ROOT/pages/references/terraform_modules/%.adoc:
	mkdir -p $(shell dirname $@)
	terraform-docs asciidoc --header-from README.adoc modules/$* > $@

app_refs: $(APP_REFS)
clean_app_refs:
	rm -f $(APP_REFS)

docs/modules/ROOT/pages/references/applications/%.adoc:
	helm-docs --template-files ../README.tmpl.md --chart-search-root argocd/$* --dry-run | pandoc --title $* -o $@
