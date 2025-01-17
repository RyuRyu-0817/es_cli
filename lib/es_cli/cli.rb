require 'thor'
require 'fileutils'
require 'open3'
require 'ruby/openai'

class EsCLI < Thor
  BASE_DIR = File.expand_path("~/ES")
  CONFIG_FILE = File.join(BASE_DIR, ".esconfig")

  
   def initialize(*args)
=begin
==================================================
homeにESフォルダ，その中に.esconfigとprofile.orgを作成
==================================================
=end        
     super
    
     # ESフォルダがなければ作成
     if !Dir.exist?(BASE_DIR)
       system("mkdir -p #{BASE_DIR}")
       puts "#{BASE_DIR} was created."
     end

     # .esconfigファイルなければ作成
     if !File.exist?(CONFIG_FILE)
       system("touch #{CONFIG_FILE}")
       puts "#{CONFIG_FILE} was created."
     end       

     # profile.orgがなければ作成
     profile_file = File.join(BASE_DIR, "profile.org")
     if !File.exist?(profile_file)       
       profile_item = <<~PROFILE
         * ガクチカ1 
         * ガクチカ2
         * 強み
         * 弱み
         * 志望業界
         * キャリアプラン
       PROFILE
       File.write(profile_file, profile_item)
       puts "#{profile_file} was created."
     end

     
   end

=begin
==================================================
・setコマンド  
==================================================
s=end           
   desc "set <apikey>", "openaiのapi_keyをセットする．セットするとaiチェックができます"
   def set(apikey)    
     File.write(CONFIG_FILE, apikey)     
   end     

=begin
==================================================
・profコマンド
==================================================
=end           
  desc "prof <item> [--copy]", "自分のprofileの項目を出力する"
  method_option :copy, type: :boolean, default: false, desc: "Copy the value to clipboard"
  def prof(item)
    profile_file = File.join(BASE_DIR, "profile.org")

    contents = File.read(profile_file)
    match = contents.match(/^\*\s+#{item}\n(.+?)(\n\*|\z)/m)

    if match
      value = match[1].strip
      puts value
      
      if options[:copy]
        case RUBY_PLATFORM

        # mac
        when /darwin/
          IO.popen('pbcopy', 'w') { |clipboard| clipboard.write(value) }

        # Linux          
        when /linux/ 
          IO.popen('xclip -selection clipboard', 'w') { |clipboard| clipboard.write(value) }

        # windows            
        when /win32|mingw|cygwin/
          IO.popen('clip', 'w') { |clipboard| clipboard.write(value) }
        else
        end
        puts "Copied to clipboard."
      end

    # matchしない場合
    else
      puts "Key '#{key}' not found in #{profile_file}."
    end
  end

=begin
==================================================
・makeコマンド
==================================================
=end  
  desc "make <company> <deadline>", "企業ごとのテンプレートを作成するコマンド" 
  def make(company, deadline)
    
    company_dir = File.join(BASE_DIR, company)

    # すでに同名のフォルダがある場合に上書きしてもよいか
    if Dir.exist?(company_dir)
      puts "Directory #{company_dir} already exists. Overwrite? (y/N)"
      is_ok = $stdin.gets.chomp.downcase
      if is_ok != 'y'
        puts "cancelled. "
        return
      end
    end

    # 企業のフォルダを作成
    system("mkdir -p #{company_dir}")
    puts "#{company_dir} was created."

    # 企業のフォルダ直下にES.org作成
    es_org = File.join(company_dir, "ES.org")
    es_item = <<~ES
         * 志望動機
         * 強み
         * 弱み
         * ガクチカ
         * 当社で実現したいこと
         * キャリアプラン
    ES
    File.write(es_org, es_item)
    puts "-#{es_org}"

    # 企業のフォルダ直下にmemo.org作成
    memo_org = File.join(company_dir, "memo.org")
    system("touch #{memo_org}")
    puts "-#{memo_org}"

    # 企業のフォルダ直下にdeadline.txt作成
    deadline_txt = File.join(company_dir, "deadline.txt")
    File.write(deadline_txt, deadline)
    puts "-#{deadline_txt}"
    
    puts "3 files were created."
  end

=begin
==================================================
・listコマンド
==================================================
=end          
  desc "list", "作成した企業のESたちを締め切り順に出力"
  def list    
    # 締め切り順にソートされた（企業名, 締め切り）を要素に持つ配列取得
    company_and_deadline = Dir.glob(File.join(BASE_DIR, "*", "deadline.txt"))
                  .map { |file| [File.basename(File.dirname(file)), File.read(file).strip] }
                  .sort_by { |_, deadline| deadline }

    if company_and_deadline.empty?
      puts "ES not found"
      exit 1
    end      

    # esが一つでもあれば  
    company_and_deadline.each do |company, deadline|
      puts "#{company} : #{deadline}"
    end
  end

=begin
==================================================
・editコマンド
==================================================
=end        
  desc "edit", "指定した企業のESを編集する，エディタ指定ない場合はvim"
  def edit(company)
    es_org = File.join(BASE_DIR, company, "ES.org")    
    system(ENV['EDITOR'] || 'vim', es_org)
  end

=begin
==================================================
・reviewコマンド
==================================================
=end          
  desc "review <company>", "書いた企業のESをaiがレビュー（動くかわからない）"
  def review(company)

    # 指定された企業のesを取得
    es_org = File.join(BASE_DIR, company, "ES.org")
    content = File.read(es_org)

    # esの内容をaiに投げる
    response = ai_review(content)
    puts "Review for #{company}: #{response}"
  end

  private

  def ai_review(content)
    api_key = File.read(CONFIG_FILE).strip
    
    # APIキーが空の場合終了
    if api_key.nil? || api_key.empty?
      puts "Error: API key is missing or empty in #{CONFIG_FILE}"
      exit 1
    end
    
    client = OpenAI::Client.new(api_key: api_key)    
    prompt = <<~PROMPT
      # 以下の内容を各項目ごとにレビューしてください:
      #{content}

      # レビューには各項目に対して以下を含めてください:
      - 書き方の改善点
      - 内容の明確さ
      - 論理的な一貫性
      - 追加できる情報があればその提案
    PROMPT

    begin
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: "あなたは優秀な編集者です。" },
            { role: "user", content: prompt }
          ],
          max_tokens: 1000
        }
      )

      response.dig("choices", 0, "message", "content").strip
    rescue StandardError => e
      "Error communicating with ChatGPT API: #{e.message}"
    end
  end    
   
end


