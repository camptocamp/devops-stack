#! /bin/sh

cd "$(dirname $0)"

mkdir -p 'supplemental_ui'

cp -RT "$(yarn global dir)/node_modules/@antora/lunr-extension/supplemental_ui/" 'supplemental_ui'

antora generate 'antora-playbook.yml' --to-dir 'public/docs'
