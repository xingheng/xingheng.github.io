help:
    open https://jekyllrb.com/docs/usage/

# Setup the initial environment
setup:
    @gem install bundler && bundle install

# Builds your site any time a source file changes and serves it locally
build:
    @bundle exec jekyll build

# Performs a one off build your site to ./_site (by default)
run:
    @bundle exec jekyll serve

# Outputs any deprecation or configuration issues
doctor:
    @bundle exec jekyll doctor

# Removes all generated files: destination folder, metadata file, Sass and Jekyll caches.
cleanup:
    @bundle exec jekyll clean
