require "bundler"
Bundler.require

class Obj::Scraper
  class Spider < Kimurai::Base
    @name = "brultech_spider"
    @engine = :selenium_chrome
    @start_urls = ["http://192.168.0.10/"]

    def self.class_init(readings_dir, status_proc)
      @readings_dir = readings_dir
      @status_proc = status_proc
    end

    def self.log(str)
      @status_proc.call(str)
      # logger.info(str)
    end

    def self.open_spider
      log "> Starting..."
    end

    def self.close_spider
      log "> Stopped!"
    end

    def self.readings_dir
      @readings_dir
    end

    def readings_dir
      self.class.readings_dir
    end

    def log(str)
      self.class.log(str)
    end

    def parse_page(table_id, day_num)
      found_table = false
      found_file = true

      log "before get response"

      sleep 1

      response = browser.current_response
      File.open("response.html", "w") {|f| f.write response}
      doc = Nokogiri::HTML(File.open("response.html"))

      date_str = doc.css("#sumSettings span.sumDateSettings").text
      if date_str == "Daily - So Far TodayDaily - So Far Today"
        date = Time.now.to_date
      else
        date = date_str
        m = /Daily - [^-]+- (.*)$/.match(date_str)
        if m
          date = Date.parse(m[1].split[1..-1].join(' '))
        else
          date = Time.now.to_date - day_num
        end
      end
      log "-------------------------------"
      log "DATE: #{date}"
      filename = "#{readings_dir}/#{date.iso8601}.json"

      if File.exist?(filename)
        log "File Exists"
        return [found_table, found_file]
      end
      found_file = false

      sleep 10

      response = browser.current_response
      File.open("response.html", "w") {|f| f.write response}
      doc = Nokogiri::HTML(File.open("response.html"))

      File.open("#{readings_dir}/#{date.iso8601}.html", "w") {|f| f.write(File.read("response.html")) }

      daily = { date: date.iso8601, readings: {} }
      css = "##{table_id} tbody tr"
      logger.info "TABLE CSS: #{css}"
      doc.css(css).each do |row|
        name = row.children[1].children[0].text
        usage = row.children[7].children[1].text

        daily[:readings][name] = usage
        # logger.info "reading: #{name} = #{usage}"
        if !found
          log "FOUND entry"
          found_table = true
        end
      end

      File.open(filename, "w") do |f|
       f.write(daily.to_json)
      end

      return [found_table, found_file]
    end

    def parse(response, url:, data: {})
      log "> Scraping..."

      day_num = 0
      num_days = 750
      index = 0

      browser.find_by_id("sumReportSelect").click
      loop do
        browser.find(:xpath, "//div[@id='sumSettingsHolder' and @class='grid-stack-item menu sumOriginal']//a[@title='Previous Period']").click

        found_table, found_file = parse_page("DataTables_Table_#{index}", day_num)

        day_num += 1
        num_days -= 1
        index += 2 if found_table
        break if num_days <= 0 || found_file
      end

      # readings = doc.css("#summaryActive .amcharts-main-div .amcharts-chart-div svg").
      #              children[7].children[0].children[0].
      #              children.map{|c| c.attributes["aria-label"].value}
    end
  end

  def self.scrape(readings_dir:, status_proc: ->(str){})
    Spider.class_init(readings_dir, status_proc)
    Spider.crawl!
  end
end
