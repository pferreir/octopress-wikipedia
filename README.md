# Introduction

This plugin adds a `{% wikipedia %}` tag that includes small boxes in your pages, containing Wikipedia article summaries. Here is [an example](http://pferreir.github.io/blog/2012/06/19/medieval-mysteries/).

# Installation

 * `$ gem install nokogiri`
 * Move `wikipedia.rb` and `wikipedia.html` into the `plugins` folder at the root of your octopress repo;
 * Move `_wikipedia.scss` into your theme's `sass/custom` dir (e.g. `.themes/custom/sass/custom`);
 * Move `w.png` into your theme's `source/images` dir;
 * Add `@import "_wikipedia.scss"` at the end of your `sass/custom/_styles.scss` files;
 * Add `gem 'nokogiri', '~> 1.6.1'` to `Gemfile` (depends on the current nokogiri version)

# Usage

    # My favorite singer:

    {% wikipedia Justin Bieber %}

Option parameters, such as `{% wikipedia Justin Bieber lang:pt %}` can be used.

## Allowed options

 * `lang` - Wikipedia language (i.e. `it` will use `it.wikipedia.org`) - default is `en`;
