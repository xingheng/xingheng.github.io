help:
    open https://jekyllrb.com/docs/usage/

# Performs a one off build your site to ./_site (by default)
run:
    @jekyll serve

# Builds your site any time a source file changes and serves it locally
build:
    @jekyll build

# Outputs any deprecation or configuration issues
doctor:
    @jekyll doctor

# Removes all generated files: destination folder, metadata file, Sass and Jekyll caches.
cleanup:
    @jekyll clean
