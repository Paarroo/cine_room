class PagesController < ApplicationController

  def home
    @creators = Movie
      .where.not(director: [nil, ""])
      .group(:director)
      .select("director, COUNT(*) AS movie_count")
      .order("movie_count DESC")
  end

end
