---
layout: post
title: "Jekyll My Blog"
date:   2014-08-23 21:49:11
---

Just migrated my blog to Jekyll, it was [a custom Rails application](https://github.com/vecio/vec.io), and I wrote a simple Ruby script to convert all Markdown text in the MongoDB to Jekyll posts.

```ruby
Post.published.each do |post|
  name = "#{post.created_at.strftime("%Y-%m-%d")}-#{post.slug}.markdown"
  File.open("_posts/#{name}", "w") do |f|
    f.puts "---"
    f.puts "layout: post"
    f.puts "title: \"#{post.title}\""
    f.puts "date:   #{post.created_at.strftime("%Y-%m-%d %H:%M:%S")}"
    f.puts "---"
    f.puts "\n"
    f.puts post.content.gsub("\r\n", "\n").gsub("```shell", "```bash")
  end
end
```

With the experience in the heavy Rails framework, it has been much easier for me to use the gems `jekyll-assets`, `autoprefixer-rails` and `jekyll-sitemap`. The Jekyll theme is highly inspired by http://rickharrison.me.

![Jekyll_theme.png]({{ '/images/2014/08/23/Jekyll_theme.png' | prepend: site.url }})
