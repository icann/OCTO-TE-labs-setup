#!/bin/bash

create_instructions () {
    ## Create instructions for students and push it to /var/www/$DOMAIN/html/grpX/instructions
    echo "Creating instructions for students and pushing it to /var/www/$DOMAIN/html/grpX/instructions ..."

    # remember working directory
    OLDPWD="$(pwd)"

    # Cleanup from older runs
    rm -rf instructions source jekyllsite

    # Create a directory for the instruction source
    apt -yq install unzip
    mkdir -p instructions
    mkdir -p source
    cd instructions
    curl -L -o instructions.zip "$INSTRUCTIONS"
    unzip instructions.zip
    mv */* ../source/
    cd ..

    # install jekyll
    apt -yq install ruby-full build-essential zlib1g-dev
    export GEM_HOME="/root/gems"
    export PATH="/root/gems/bin:$PATH"
    gem install jekyll bundler

    # start new jekyll site
    jekyll new jekyllsite
    cd jekyllsite

    # delete any index file, we want README to be the index
    rm index*

    for grp in $(seq 1 $NETWORKS)
    do
        # get configuration
        cp ../../configs/jekyll/* .

        # install dependencies
        bundle install

        # substitute in group number and domain 
        sed -i -e "s/%GRP%/${grp}/g" -e "s/%DOMAIN%/${DOMAIN}/g" _config.yml

        # get content
        cp -a ../source/. ./

        # substitute in group number and domain
        find . -type f \( -name '*.md' -o -name '*.svg' \) -print0 |
        while IFS= read -r -d '' file; do
            sed -i \
                -e "s/%GRP%/${grp}/g" \
                -e "s/%DOMAIN%/${DOMAIN}/g" \
                -e "s/%IPv6pfx%/${IPv6prefix}/g" "$file"
        done

        # build the site
        bundle exec jekyll build

        # copy the built site to the output directory
        rm -rf /var/www/${DOMAIN}/html/grp${grp}/instructions
        mkdir -p /var/www/${DOMAIN}/html/grp${grp}/instructions
        mv _site/* /var/www/${DOMAIN}/html/grp${grp}/instructions
    done

    # back to the old working directory
    cd $OLDPWD

    # finally we are 
    echo "Lab instructions are now available for all groups."
}
