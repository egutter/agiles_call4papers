class ApiSessionsController < ApplicationController
  skip_before_filter :login_required
  
  def index
    @sessions = Session.all
    render :xml => @sessions
  end
  
  def show
    @session = Session.find(params[:id])
    render :xml => @session
  end
  
end
