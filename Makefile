
APPLICATIONS = $(shell ls argocd)
APP_REF = $(addsuffix .adoc,$(addprefix docs/modules/ROOT/pages/references/applications/,$(APPLICATIONS)))

app_refs: $(APP_REF)

docs/modules/ROOT/pages/references/applications/%.adoc:
	cat argocd/$*/README.md argocd/$*/REFERENCE.md | pandoc -o $@

argocd/%/README.md: helm-docs

helm-docs:
	helm-docs -o REFERENCE.md
