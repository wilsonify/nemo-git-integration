# Documentation Site

This directory contains the documentation website for Nemo Git Integration, built with [Jekyll](https://jekyllrb.com/) and the [just-the-docs](https://just-the-docs.com/) theme.

## Local Development

### Prerequisites

- Ruby 2.7 or higher
- Bundler gem

### Setup

1. Install dependencies:

```bash
cd docs
bundle install
```

2. Run the local server:

```bash
bundle exec jekyll serve
```

3. View the site at `http://localhost:4000`

The site will automatically rebuild when you make changes to files.

### Live Reload

For automatic browser refresh when files change:

```bash
bundle exec jekyll serve --livereload
```

## Site Structure

```
docs/
├── _config.yml              # Jekyll & just-the-docs configuration
├── Gemfile                  # Ruby dependencies
├── index.md                 # Home page
├── user.md                  # User Guide (parent page)
├── admin.md                 # Administrator Guide
├── developer.md             # Developer Guide (parent page)
├── user/
│   └── uninstall.md        # Child page under User Guide
└── developer/
    ├── building.md         # Child page under Developer Guide
    ├── gpg-signing.md      # Child page under Developer Guide
    └── maintainer-validation.md  # Child page under Developer Guide
```

## Navigation Structure

The site uses just-the-docs navigation with the following hierarchy:

1. **Home** (index.md)
2. **User Guide** (user.md) - Parent page
   - Uninstall and Cleanup (user/uninstall.md)
3. **Administrator Guide** (admin.md)
4. **Developer Guide** (developer.md) - Parent page
   - Building and Installing (developer/building.md)
   - GPG Signing Setup (developer/gpg-signing.md)
   - Maintainer Validation (developer/maintainer-validation.md)

## Adding New Pages

### Create a new top-level page:

```markdown
---
layout: default
title: Your Page Title
nav_order: 5
---

# Your Page Title

Content here...
```

### Create a child page:

```markdown
---
layout: default
title: Child Page Title
parent: Parent Page Title
nav_order: 1
---

# Child Page Title

Content here...
```

### Create a grandchild page:

```markdown
---
layout: default
title: Grandchild Page Title
parent: Child Page Title
grand_parent: Parent Page Title
nav_order: 1
---

# Grandchild Page Title

Content here...
```

## Theme Customization

just-the-docs supports extensive customization:

- **Color schemes**: Edit `_config.yml` to change `color_scheme`
- **Search**: Enabled by default, configure in `_config.yml`
- **Navigation**: Automatic based on front matter
- **Code highlighting**: Built-in support for syntax highlighting
- **Callouts**: Use for warnings, notes, and tips

### Example Callout

```markdown
{: .warning }
This is a warning callout!

{: .note }
This is a note callout.

{: .tip }
This is a tip callout.
```

## GitHub Pages Deployment

This site can be deployed to GitHub Pages. Add to your repository's `Settings > Pages`:

- **Source**: Deploy from a branch
- **Branch**: `main` or `gh-pages`
- **Folder**: `/docs`

GitHub Pages will automatically build the Jekyll site when you push changes.

## Additional Resources

- [just-the-docs Documentation](https://just-the-docs.com/)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Markdown Guide](https://www.markdownguide.org/)

## Troubleshooting

### Bundle install fails

Make sure you have Ruby 2.7+ and development headers:

```bash
# Debian/Ubuntu
sudo apt-get install ruby-full build-essential zlib1g-dev

# Set gem install path
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Port 4000 already in use

Kill the existing process or use a different port:

```bash
bundle exec jekyll serve --port 4001
```

### Changes not reflecting

Clear Jekyll cache and rebuild:

```bash
bundle exec jekyll clean
bundle exec jekyll serve
```
