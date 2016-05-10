require 'sad_panda'
require 'madeleine'
include ActionView::Helpers::NumberHelper
class TweetController < ApplicationController
  skip_before_action :verify_authenticity_token
  @@m = SnapshotMadeleine.new("bayes_data") {
          Classifier::Bayes.new 'Democratic', 'Republican'
  }
  def index
    begin
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
      party = params['party']
      client = Mysql2::Client.new(:host => "localhost", :database => "TweetAnalysis_development", :username => "root", :password => "root")
      @keywords = client.query("select * from keywords where party=#{party}") 
      render :json => @keywords.to_json, :status => 200 
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
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
      puts "Training Classifier Started !"
      Predict.delete_all 
      data = Tweet.all 
      data.each do |record|
        Predict.create(id: record.id, screen_name: record.screen_name, text: record.text, actual: record.political_affiliation)
      end  
      fold = cross_validation()
      @tweets = Predict.all
      @tweets.each do |tweet|
        if tweet["predicted#{fold}"] == 1
           @@m.system.train_democratic tweet.text
        elsif tweet["predicted#{fold}"] == 2
           @@m.system.train_republican tweet.text
        end
      end  
      @@m.take_snapshot
      puts "Training Classifier Complete !"
      render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def test_classifier
    begin 
    key = params['key']
    count = params['count']
    @tweets = $my_twitter.search("#{key} -rt", result_type: "recent", lang: 'en').take(count.to_i)
    @tweets.each do |latest_tweet|
      dup_text = latest_tweet.text.dup
      t_party = @@m.system.classify dup_text
      sentiment = SadPanda.emotion(dup_text)
      score = SadPanda.polarity(dup_text)
      if t_party == "Democratic"
        party = 1
      elsif t_party == "Republican"
        party = 2
      end
      Tweet.create(text: dup_text, screen_name: latest_tweet.user.screen_name, 
        score: score, sentiment: sentiment, user_id: latest_tweet.user.id, political_affiliation: party, mode: '2')
      puts "screen_name : #{latest_tweet.user.screen_name} and party : #{party}"
    end
    puts "Testing Classifier Complete !"
    render :nothing => true, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def getDemocratsList
    begin
      @democrats = Tweet.select( "screen_name" ).where( political_affiliation: 1 ).uniq
      puts "Get Democrats List Complete !"
      render :json => @democrats.to_json, :status => 200 
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def getRepublicanList
    begin
      @republicans = Tweet.select( "screen_name" ).where( political_affiliation: 2 ).uniq
      puts "Get Republicans List Complete !"
      render :json => @republicans.to_json, :status => 200 
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def get10Tweets
    begin
      client = Mysql2::Client.new(:host => "localhost", :database => "TweetAnalysis_development", :username => "root", :password => "root")
      @result = client.query("select keyword_id, text from tweets where keyword_id is not null  group by keyword_id, text limit 10;")
      render :json => @result.to_json, :status => 200
    rescue Exception => e
      puts e.message
      render :nothing => true, :status => 500
    end
  end
  def cross_validation
    puts "Cross Validation Started !"
    client = Mysql2::Client.new(:host => "localhost", :database => "TweetAnalysis_development", :username => "root", :password => "root")
    result = client.query("select count(*) - count(*)/10 as Training, count(*)/10 as Testing from cross_validation;")
    training = 0
    testing = 0
    result.each do |row|
     training = row["Training"].to_f
     testing = row["Testing"].to_f
    end
    puts "Training Records Count : #{training} , Testing Records Count : #{testing}"
    accuracy = []  
    fold = 10
    i = 1
    while i <= fold do
      puts "Cross Validation: Fold #{i} started"
      _start = (i - 1) * testing
      _end = i * testing - 1
      setFold( _start, _end )
      cross_validate(i)
      accuracy << calculate_accuracy(i)
      puts "Cross Validation: Fold #{i} complete."
      i += 1
    end 
    max_accuracy = accuracy.max
    max_accuracy_fold = accuracy.index(accuracy.max) + 1
    puts "Accuracies #{accuracy}"
    puts "Maximum Accuracy at: Fold #{max_accuracy_fold} with Accuracy #{max_accuracy}"
    puts "Cross Validation Complete !"
    return max_accuracy_fold
  end
  def cross_validate(fold)
    begin 
      client = Mysql2::Client.new(:host => "localhost", :database => "TweetAnalysis_development", :username => "root", :password => "root")
      predicted_field = "predicted#{fold}"
      #Train 9/10 folds - classifier   
      classifier = Classifier::Bayes.new 'Democratic', 'Republican'
      table = client.query("select * from cross_validation where mode = '1';")
      table.each do |record|
        if record["actual"].to_i == 1
           classifier.train_democratic record["text"]
        elsif record["actual"].to_i == 2
           classifier.train_republican record["text"]
        end
      end 

      #Test 1/10 fold - classifier
      test = client.query("select * from cross_validation where mode = '2';")
      t_party = ""
      party = 0
      _id = 0
      test.each do |record|
        t_party = classifier.classify record["text"]
        if t_party == "Democratic"
          party = 1
        elsif t_party == "Republican"
          party = 2
        end
        _id = record["id"]
        client.query("update cross_validation set #{predicted_field} = '#{party}' where id = '#{_id}';")
      end   
    rescue Exception => e
      puts e.message
    end
  end
  def setFold(_start, _end)
    i = 0
    table = Predict.all
    table.each do |record|
      if i >= _start && i <= _end
        record.attributes = { :mode => 2 }
      else     
        record.attributes = { :mode => 1 }
      end
      record.save
      i += 1
    end  
  end
  def calculate_accuracy(fold)
    table = Predict.all
    record_count = table.length
    accuracy_count = 0
    table.each do |record|
      if record["actual"].to_i == record["predicted#{fold}"].to_i
        accuracy_count += 1
      end
    end
    accuracy = ( accuracy_count.to_f / record_count ) * 100
    return number_with_precision( accuracy , precision: 2)
  end
end