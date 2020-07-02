require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require 'sinatra/activerecord'
require './models'



# ============================ ↓ ここから gem などのライブラリの項目 ↓ ============================

# Twitter のAPIを使うための gem をここで読み込み
require 'oauth'
require 'json'


# 公開されるとダメな大切な情報を管理する gem をここで読み込み
require 'dotenv'
# ファイル .env の内容を読み込み
Dotenv.load



# ========================= ↓ ここから Twitter のAPIを使うための下準備 ↓ =========================

before do
  # 読み込んだファイル .env の内容から、API に必要な情報を変数に格納
  consumer_key        = ENV["twi_consumer_key"]
  consumer_secret     = ENV["twi_consumer_secret"]
  access_token        = ENV["twi_access_token"]
  access_token_secret = ENV["twi_token_secret"]

  consumer = OAuth::Consumer.new(
    consumer_key,
    consumer_secret,
    {
      :site   => 'http://api.twitter.com',
      :scheme => :header
    }
  )
  token_hash = {
    :access_token        => access_token,
    :access_token_secret => access_token_secret
  }

  # Twitterへのリクエストトークン作成
  @client = OAuth::AccessToken.from_hash(consumer, token_hash)


  # Twitter API を使ってトレンドを取得可能な場所のリストを取ってくる。 形式をjsonに変えて @location_list に保存
  response_available = @client.request(:get, 'https://api.twitter.com/1.1/trends/available.json')
  @location_list = JSON.parse(response_available.body)
end



# ================================ ↓ ここから 実際のページの処理 ↓ ================================

# トップページ

get '/' do
  erb :index
end

# 検索した時のページ(一瞬で処理が終わってトップページに戻る)

post '/search' do
  # 検索ボックスで入れたキーワード(国名 Japan など)を @keyword に保存。
  puts "Search keyword >> #{params[:keyword]}"
  @keyword = params[:keyword]

  # トレンドを取得可能な場所のリスト @location_list から キーワード @keyword の国名を探す。
  target_id = nil
  @location_list.each do |available|
    # 発見できれば woeid と呼ばれる ID を target_id に保存。
    if available["name"] == @keyword then
      target_id = available["woeid"]
      break
    end
  end

  # target_id に保存した国のIDから、トレンドを検索する。結果を @target_trends に保存。
  response_place = @client.request(:get, 'https://api.twitter.com/1.1/trends/place.json?id=' + target_id.to_s)
  @target_trends = JSON.parse(response_place.body)

  # トップページの画面に戻る
  erb :index
end
