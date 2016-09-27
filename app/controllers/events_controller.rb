class EventsController < ApplicationController
	before_action :set_event, :only => [:show, :edit, :update, :destroy]

	def index
		@event = Event.page(params[:page]).per(5)
	end

	def new
		@event = Event.new
	end

	def create
		raise
		@event = Event.new(event_params)
		if @event.save
        	redirect_to events_url
        	flash[:notice] = "event was successfully created"
        else
        	render :action =>:new
        end

	end

	def show
		@page_title = @event.name
	end

	def edit
	end

	def update
		raise
		if @event.update(event_params)
        	redirect_to event_url(@event)
        	flash[:notice] = "event was successfully updated"
        else
        	render :action => :edit
        end
	end

	def destroy
		@event.destroy
		flash[:notice] = "event was successfully deleted"
		redirect_to events_url
	end

	private

	def event_params
		params.require(:event).permit(:name, :description)
	end

	def set_event
		@event = Event.find(params[:id])
	end
end
