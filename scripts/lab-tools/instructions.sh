#!/bin/bash

create_instructions () {
    ## Create instructions for students and push it to /var/www/$DOMAIN/html/grpX/instructions
    echo "Creating instructions for students and pushing it to /var/www/$DOMAIN/html/grpX/instructions ..."

    # remember working directory
    OLDPWD="$(pwd)"

    # Check if required parameters are set
    if [ -z "$INSTRUCTIONS" ]; then
        echo "No source for instructions is set. Nothing to do!"
        echo "If you want to use instructions, set the INSTRUCTIONS variable in deploy-parameters.cfg."
        exit 0;
    fi

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

        # replace lab_domain and X 
        sed -i -e "s/X/${grp}/g" -e "s/lab_domain/${DOMAIN}/g" _config.yml

        # get content
        cp -a ../source/. ./

        # replace lab_domain and X
        find . -type f -name '*.md' -print0 | while IFS= read -r -d '' file; do
            sed -i -e "s/X/${grp}/g" -e "s/lab_domain/${DOMAIN}/g" "$file"
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
