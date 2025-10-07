require 'rake'

namespace :assets do
    desc 'Build frontend assets using Vite'
    task :build do
        sh 'npm run build'
    end

    desc 'Clean built frontend assets'
    task :clean do
        rm_rf 'public/assets'
    end
end

desc 'Show project info'
task :info do
    puts 'SiteCard project: modular Ruby backend, Vite frontend, Nginx as static server'
end
