require 'rake'

namespace :assets do
    desc 'Build frontend assets using Vite'
    task :build do
        begin
            sh 'npm run build'
            puts "Assets built successfully"
        rescue => e
            puts "Asset build failed: #{e.message}"
            puts e.backtrace.join("\n")
            exit 1
        end
    end

    desc 'Clean built frontend assets'
    task :clean do
        begin
            rm_rf 'public/assets'
            puts "Assets cleaned successfully."
        rescue => e
            puts "Asset clean failed: #{e.message}"
            puts e.backtrace.join("\n")
            exit 1
        end
    end
end

desc 'Show project info'
task :info do
    begin
        puts 'SiteCard project: modular Ruby backend, Vite frontend, Nginx as static server'
    rescue => e
        puts "Info task failed: #{e.message}"
        puts e.backtrace.join("\n")
        exit 1
    end
end
