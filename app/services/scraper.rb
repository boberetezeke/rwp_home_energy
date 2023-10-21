require "bundler"
Bundler.require

# doc = Nokogiri::HTML(File.open("response.html"))
# doc.css("#DataTables_Table_0 tbody tr").each do |row|
#   name = row.children[1].children[0].text
#   usage = row.children[7].children[1].text
#   data = {name: name, usage: usage}
#   puts("row =#{data}")
# end
#
# exit

class ExampleSpider < Kimurai::Base
    @name = "brultech_spider"
    @engine = :selenium_chrome
    @start_urls = ["http://192.168.0.10/"]
    # @config = {
    #     before_request: {
    #       # Process delay before each request:
    #       delay: 3..5
    #     }
    #   }
    def self.open_spider
      logger.info "> Starting..."
    end
  
    def self.close_spider
      logger.info "> Stopped!"
    end

    def parse_page(table_id, day_num)
      logger.info "before get response"

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
      logger.info "-------------------------------"
      logger.info "DATE: #{date}"
      filename = "readings/#{date.iso8601}.json"

      if File.exist?(filename)
        logger.info "File Exists"
        return false
      end

      sleep 10

      response = browser.current_response
      File.open("response.html", "w") {|f| f.write response}
      doc = Nokogiri::HTML(File.open("response.html"))

      File.open("readings/#{date.iso8601}.html", "w") {|f| f.write(File.read("response.html")) }

      daily = { date: date.iso8601, readings: {} }
      css = "##{table_id} tbody tr"
      logger.info "TABLE CSS: #{css}"
      found = false
      doc.css(css).each do |row|
        name = row.children[1].children[0].text
        usage = row.children[7].children[1].text

        daily[:readings][name] = usage
        # logger.info "reading: #{name} = #{usage}"
        if !found
          logger.info "FOUND entry"
          found = true
        end
      end
      File.open(filename, "w") do |f|
       f.write(daily.to_json)
      end

      return found
    end


    def parse(response, url:, data: {})
      logger.info "> Scraping..."

      day_num = 0
      num_days = 750
      index = 0

      browser.find_by_id("sumReportSelect").click
      loop do
        browser.find(:xpath, "//div[@id='sumSettingsHolder' and @class='grid-stack-item menu sumOriginal']//a[@title='Previous Period']").click

        found_table = parse_page("DataTables_Table_#{index}", day_num)

        day_num += 1
        num_days -= 1
        index += 2 if found_table
        break if num_days <= 0
      end

      # readings = doc.css("#summaryActive .amcharts-main-div .amcharts-chart-div svg").
      #              children[7].children[0].children[0].
      #              children.map{|c| c.attributes["aria-label"].value}
    end
  end
  
  ExampleSpider.crawl!
