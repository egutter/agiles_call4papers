class ApiAuthorsController < ApplicationController
  skip_before_filter :login_required
  
  def index
    @authors = User.all
    render :xml => @authors
  end
  
  def show
    @author = User.find(params[:id])
    render :xml => @author
  end

end
