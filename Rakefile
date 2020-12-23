require 'bundler'
Bundler.setup
require 'dotenv'
Dotenv.load!
require_relative 'lib/hsp_db'

Bundler.require
require 'pp'

require_relative 'lib/vsp'
require_relative 'lib/cohort'
require_relative 'lib/composer'

APP_ROOT = Pathname('.').realpath
TMP_DIR = APP_ROOT + 'tmp'
OUTPUT_DIR = APP_ROOT + 'output' + Date.today.strftime('%Y%m%d')
LOG_DIR = APP_ROOT + 'log'

directory OUTPUT_DIR
directory TMP_DIR
directory LOG_DIR

desc 'generate the VSP EDI file'
task :generate => [OUTPUT_DIR, TMP_DIR] do
  production = ENV['APP_STAGE'] == 'production'

  output_dir = production ? OUTPUT_DIR : TMP_DIR

  File.open(output_dir + VSP::Filename.new(production: production).to_s, 'w') do |f|
    f.puts Composer.new(production: production, dataset: Cohort.dataset)
  end
end