require 'sad_panda'
require 'madeleine'
class TweetController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    begin
  	 @keywords = Keyword.all
    rescue Exception => e
      puts e.message
    end
  end
  def addKeyword
    begin
    	@keyword = params['keyword']
      @party = params['party']
    	Keyword.create(name: @keyword, party: @party)
    	render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def deleteKeyword
    begin
    	@id = params['id']
    	Keyword.where(id: @id).destroy_all
    	render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def getTweets
    begin
      count = params['count']
      keywords = Keyword.all
      @tweets = Array.new
      keywords.each do |keyword| 
        @temp = $my_twitter.search("#{keyword.name} -rt", result_type: "recent", lang: 'en').take(count.to_i)
        @temp.each do |tweet|
          dup_text = tweet.text.dup
          sentiment = SadPanda.emotion(dup_text)
          score = SadPanda.polarity(dup_text)
          Tweet.create(text: tweet.text, screen_name: tweet.user.screen_name, keyword_id: keyword.id, score: score, sentiment: sentiment, user_id: tweet.user.id, political_affiliation: keyword.party)
        end
        @tweets.concat(@temp) 
      end 
      render :partial => 'tweet_list', :locals => { :tweets => @tweets }, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def resetDB
    begin
      Keyword.destroy_all
      Tweet.destroy_all
      render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def deleteAllTweets
    begin
      Tweet.destroy_all
      render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end 
  end
  def getSentiments
    begin
      client = Mysql2::Client.new(:host => "localhost", :database => "TweetAnalysis_development", :username => "root", :password => "root")
      @result = client.query("select k.name as keyword, t.sentiment as dimension, count(t.sentiment) as tweet_count from tweets t inner join keywords k on t.keyword_id = k.id group by keyword, sentiment;")
      puts @result.to_json
      render :json => @result.to_json, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def getKeywords
    begin
      @keywords = Keyword.find_by! party: params['party']
      render :json => @keywords.to_json, :status => 200 
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def showKeywordsByParty
    party = params['party']
  end
  def getDimensions
    begin
      client = Mysql2::Client.new(:host => "localhost", :database => "TweetAnalysis_development", :username => "root", :password => "root")
      @result = client.query("select distinct sentiment as dimension from tweets;")
      render :json => @result.to_json, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def train_classifier
    begin    
      @m = SnapshotMadeleine.new("bayes_data") {
          Classifier::Bayes.new 'Democratic', 'Republican'
      }
      @tweets = Tweet.all
      @tweets.each do |tweet|
        if tweet.party == 1
           @m.system.train_democratic tweet.text
        elsif tweet.party == 2
           @m.system.train_republican tweet.text
        end
      end  
      @m.take_snapshot
      @m.system.classify "I love Hillary"
      render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
end
