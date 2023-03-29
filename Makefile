WEBSITE_URL ?= https://devops-stack.io

MODULES = $(shell find 'modules' -name 'README.adoc' -printf '%P\n' | xargs -d '\n' -n 1 dirname)
MOD_REFS = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/terraform_modules/,$(MODULES)))

APPLICATIONS = $(shell find 'argocd' -name 'values.yaml' -printf '%P\n' | xargs -d '\n' -n 1 dirname)
APP_REFS = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/applications/,$(APPLICATIONS)))

.PHONY: help website docs clean refs clean_refs mod_refs clean_mod_refs app_refs clean_app_refs

help: # List targets
	@sed -rn 's/^(\S+): .*(# (.+))$$/\1\t\3/p' '$(MAKEFILE_LIST)' | sort | awk -F '\t' '{ printf "%-20s %s\n", $$1, $$2; }'

website: # Generate website
	hugo --minify --source 'website' --destination '../public' --baseURL '$(WEBSITE_URL)'

docs: refs # Generate documentation
	cp -RT "$$(yarn global dir)/node_modules/@antora/lunr-extension/supplemental_ui/" 'docs/supplemental_ui'
	URL='$(WEBSITE_URL)/docs' antora generate 'antora-playbook.yml' --to-dir 'public/docs'
	ln -sf "$$(cat version.txt)" 'public/docs/latest'

clean: clean_refs # Clean up generated files

refs: mod_refs app_refs
clean_refs: clean_mod_refs clean_app_refs

mod_refs: $(MOD_REFS)
clean_mod_refs:
	rm -f $(MOD_REFS)

docs/modules/ROOT/pages/references/terraform_modules/%.adoc: modules/%/*variables.tf
	mkdir -p "$$(dirname '$@')"
	terraform-docs 'asciidoc' --header-from 'README.adoc' 'modules/$*' > '$@'

app_refs: $(APP_REFS)
clean_app_refs:
	rm -f $(APP_REFS)

docs/modules/ROOT/pages/references/applications/%.adoc: argocd/%/values.yaml
	mkdir -p "$$(dirname '$@')"
	helm-docs --template-files '../README.tmpl.md' --chart-search-root 'argocd/$*' --dry-run | pandoc --title '$*' -o '$@'
