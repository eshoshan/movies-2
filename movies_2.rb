#implement two classes: MovieData and MovieTest

#MovieData:

class MovieData

	# constructor: takes path to folder containing movie data (eg. ml-100k)
	# u.data is training set & test set is empty

	# optional constructor: used to specify particular base/training set pair to read
	def initialize (folder, f=nil)
		if(f.nil?)
			if(File.directory?(folder))
				f = File.new(folder + "/u.data")
				# checks if u.data exists in the provided path
				if(File.exist?(f))
				# opens file & reads data into training_set
				training = open(f)
				@training_set = training.read
				@test_set = ''
				end
			end
		else
			if(File.directory?(folder))
				f1 = File.new(folder + '/' + f.to_s + '.base')
				f2 = File.new(folder + '/' + f.to_s + '.test')
				if(File.exist?(f1) && File.exist?(f2))
					training = open(f1)
					@training_set = training.read
					test = open(f2)
					@test_set = test.read
				end
			end
		end
	end
	
	#read in the data from original ml-100k
	#files and store them in whatever way 
	#they need to be stored
	def load_data
		lines = @training_set.split("\n")
		# user: {user_id => {movie_id => rating}}
		@user ={}
		# ranking: {moive_id => rating}
		@ranking = {}
		# viewers = {movie_id => [user_id, user_id]}
		@viewers = {}

		lines.each do |line|
			a = line.split("\t")
			if @user.has_key?(a[0])
				stuff = @user[a[0]]
				stuff[a[1]] = a[2]
			else 
				@user[a[0]] = {a[1] => a[2]}
			end

			# maintains an average rating of a movie_id
			if @ranking.has_key?(a[1])
				rank = @user[a[1]]
				temp = @ranking[a[1]] + a[2].to_i
				temp = temp/2
				@ranking[a[1]] = temp
			else 
				@ranking[a[1]] = a[2].to_i
			end

			if @viewers.has_key?(a[1])
				stuff = @viewers[a[1]]
				stuff.push(a[0])
				@viewers[a[1]] = stuff
			else
				@viewers[a[1]] = [a[0].to_i]
			end

		end
	end

	#rating(u,m): returns rating that user u gave movie m in training set
	# returns 0 if user u did not rate movie m

	def rating(u, m)
		if(@user.has_key?(u))
			temp = @user[u]
			if(temp.has_key?(m))
				return temp[m]
			end
		end
		return 0

	end

	# predit(u, m): returns a floating point number between 1.0 and 5.0 as
	# an estimate of what user u would rate movie m

	def predict(u, m)
	# find the user most similar: if they've rated the movie, give their rating
	# if they haven't rated the movie, return average ranking of movie

		# calculate the user most similar to u
		ms = most_similar(u)
		# store most similar user hash value -- {movie_id => rating}
		movierank = @user[ms]
		# if hash contains the key of movie m
		if(movierank.has_key?(m))
			# return the ranking the most similar user gave
			return movierank[m].to_f
		else  
			# else, user hasn't rated/watched that movie
			# so return the average ranking for movie m
			return @ranking[m].to_f
		end

	end


	#generates a number which indicates
	#the similarity in movie preference b/t
	#user1 and user2 (high # = greater similarity)

	def similarity(user1, user2) 
		# if either of given users don't exist in the hash, return 0
		if(!@user.has_key?(user1) || !@user.has_key?(user2))
			return 0
		else
			rank1 = @user[user1] 	# returns hash of {movie_id=> rating} for user1
			rank2 = @user[user2]	# returns hash of {movie_id => rating} for user2
			lr1 = rank1.length
			lr2 = rank2.length
			diff = {}
			if(lr1>lr2)	#if user1 hash greater than user 2
				diff = rank1.to_a-rank2.to_a 	#store the difference of two hashes in array
				ld = diff.length 	#calculate length of difference array
				return ((lr1-ld).to_f/lr1)*100 	#returns (user1 hash length - difference array length)/user 1 hash length 
			else #if user2 hash greater than user 1
				diff = rank2.to_a-rank1.to_a #store the difference of two hashes in array
				ld = diff.length 	#calculate length of difference array
				return ((lr2-ld).to_f/lr2)*100 	#returns (user2 hash length - difference array length)/user 2 hash length 
			end
		end
	end

	#returns a list of users whose tastes
	#are most similar to the tastes of user u
	def most_similar(u)
		# if user doesn't exist in the hash, return 0
		if(!@user.has_key?(u))
			return 0
		else
			list ={}
			# for each key in user, calculate similarity and then store in hash {u=>similarity}
			@user.keys.each do |u1|
				s = similarity(u, u1)
				list[u1] = s
			end

			# sort list by similarity & return the 1st result
			l = list.sort_by { |user, similarity| similarity }
			return l[0][0]
		end
		
	end

	# movies(u) returns the array of movies that user u has watched
	def movies(u)
		if(@user.has_key?(u))
			@user[u].keys
		end
	end

	# viewers(m) returns the array of users that have seen movie m
	def viewers(m)
		if(@viewers.has_key?(m))
			@viewers[m]
		end
	end

	# run_test(k) runs the predict method on the first k ratings in the test
	# set and returns a MovieTest object containing the results
		# parameter k is optional and if omitted, all of tests will run

	def run_test(k=nil)
		mt = MovieTest.new()
		ts = @test_set.split("\n")
		if(!ts.empty?)
			# if no upper bound is passed, run all of the data in test set
			if(k.nil?)
				# iterates through each line of array
				ts.each do |line|
					# splits by tab
					tab = line.split("\t")
					# appends the result to the String representation of results in Movie Test
					mt.add_result(tab[0], tab[1], tab[2], predict(tab[0], tab[1]))
				end
			# upper bound k is passed, run the first k ratings in test set
			else
				# resizes existing test set array to the first k rating
				ts2 = Array.new(k) {|i| ts[i]}
				# iterates through each line of array
				ts2.each do |line|
					# splits by tab
					tab = line.split("\t")
					# appends the result to the String representation of results in Movie Test
					mt.add_result(tab[0], tab[1], tab[2], predict(tab[0], tab[1]))
				end
			end
			return mt
		else 
			return mt
		end
	end

	def user
		@user
	end

	def ranking
		@ranking
	end

	def viewers
		@viewers
	end

end


# MovieTest is generated by the z.run_test(k) and it stores a list of all the results,
# where each result is a tuple containing the user, movie, rating and the predicted rating

class MovieTest

	def initialize
		@list = ""
	end

	def add_result(u, m, r, p)
		@list << u.to_s + "\t" + m.to_s + "\t" + r.to_s + "\t" + p.to_s + "\n"
	end

	# mean returns the average prediction error (which should be close to zero)
	def mean()
		mean = 0
		lines = to_a()
		lines.each do |line|
			tab = line.split("\t")
			# (rating + prediction)/2
			temp = tab[2].to_f + tab[3].to_f
			temp = temp/2
			mean = (temp + mean)/2
		end
		return mean
	end

	# stddev() returns the standard deviation of the error
	def stddev()
		# find mean
		mean = mean()
		lines = to_a()
		stddev = 0
		squared = 0
		lines.each do |line|
			tab = line.split("\t")
			# for each number, subtract mean from it
			temp = tab[3].to_f - mean
			# square the result
			temp = temp*temp
			# maintain mean of the squared
			squared = (squared + temp)/2
		end
		# take the square root of mean/squared
		stddev = Math.sqrt(squared)
		return stddev
	end

	# rms returns the root mean square error of the prediction
	def rms()
		lines = to_a()
		rms = 0
		squared = 0
		lines.each do |line|
			tab = line.split("\t")
			# for each number, subtract prediction from actual
			temp = tab[2].to_f - tab[3].to_f
			# square the result
			temp = temp*temp
			# maintain mean of squared
			squared = (squared + temp)/2
		end
		# take the square root of mean/squared
		rms = Math.sqrt(squared)
		return rms
	end


	# to_a () returns an array of the predictions in the form [u, m, r, p]
	# you can also generate other types of error measures if you want, but 
	# we will rely mostly on the root mean square error
	def to_a()
		@list.split("\n")
	end

end

# m = MovieData.new("ml-100k")
# m.load_data

# puts m.rating("196", "242")
# puts m.movies("196")
# puts m.viewers("242")

m = MovieData.new("ml-100k", :u1)
m.load_data

puts m.predict('196', '241')
mt = m.run_test(40)
puts mt.mean
puts mt.rms
puts mt.stddev
# puts mt.to_a


# Ask about how to handle the empty test set in default constructor

