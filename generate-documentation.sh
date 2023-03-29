#! /bin/sh

cd "$(dirname $0)"

cp -RT "$(yarn global dir)/node_modules/@antora/lunr-extension/supplemental_ui/" 'docs/supplemental_ui'

antora generate 'antora-playbook.yml' --to-dir 'public/docs'
