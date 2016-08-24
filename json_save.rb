require 'net/https'

uri = URI('https://trello.com/b/LvwOjrYP/ingress-medal-arts.json')
def save(uri)
	Net::HTTP.start(uri.host, uri.port,:use_ssl => uri.scheme == 'https') do |http|
	  request = Net::HTTP::Get.new uri
	  http.request request do |response|
		  open 'ingress-medal-arts.json', 'wb' do |io|
			  response.read_body do |chunk|
				  io.write chunk
			  end
		  end
	  end
	end
	puts 'success update json'
end

#save(uri)