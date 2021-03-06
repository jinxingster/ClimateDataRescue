class TranscriptionsController < ApplicationController
  #load_and_authorize_resource
  respond_to :html, :json, :js
  layout 'layouts/transcriber', :only => [:edit]
  #Corresponds to the "transcription" model, transcription.rb. The functions defined below correspond with the various CRUD operations permitting the creation and modification of instances of the transcription model
  #All .html.slim views for "transcription.rb" are located at "project_root\app\views\transcriptions"
  
  # GET /transcriptions
  # GET /transcriptions.json
  def index
    if current_user
      if current_user.admin?
        #@transcriptions is the variable containing all instances of the "transcription.rb" model passed to 
        #the transcription view "index.html.slim" (project_root/transcriptions) and is used to populate the 
        #page with information about each transcription using @transcriptions.each (an iterative loop).
        @transcriptions = Transcription.all
      else
        @transcriptions = current_user.transcriptions
      end
    else
      flash[:danger] = 'Only users can modify transcriptions! <a href="' + new_user_session_path + '">Log in to continue.</a>'
      redirect_to root_path
    end
  end

  def my_transcriptions
    if params[:user_id]
      begin
        user = User.find params[:user_id]
        @transcriptions = user.transcriptions
        render "index"
      rescue => e
        flash[:danger] = e.message
        redirect_to root_path
      end
    end
  end

  # GET /transcriptions/transcription_id
  # GET /transcriptions/transcription_id.json
  def show    
    if current_user
      # @transcription is a variable containing an instance of the "transcription.rb" model. 
      # It is passed to the transcription view "show.html.slim" (project_root/transcriptions/transcription_id)
      # and is used to populate the page with information about the transcription instance.
      @transcription = Transcription.find(params[:id])
      # @page = @transcription.page
    
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @transcription }
      end
    else
      flash[:danger] = 'Only users can view transcriptions! <a href="' + new_user_session_path + '">Log in to continue.</a>'
      redirect_to root_path
    end
  end

  # GET /transcriptions/new
  # GET /transcriptions/new.json
  def new
    if current_user
      # @transcription is a variable containing an instance of the "transcription.rb" model.
      # It is passed to the transcription view "new.html.slim" (project_root/transcriptions/new)
      # and is used to populate the page with information about the transcription instance.
      # "new.html.slim" loads the reusable form "_form.html.slim" which loads input fields to 
      # set the attributes of the new transcription instance.
      @user = current_user
      get_or_assign_page(params[:current_page_id])
      @field_groups = @page.page_type.field_groups if @page && @page.page_type
      @transcription = Transcription.new
      
    else
      flash[:danger] = 'Only users can modify transcriptions! <a href="' + new_user_session_path + '">Log in to continue.</a>'
      redirect_to root_path
    end
  end

  # GET /transcriptions/transcription_id/edit
  def edit
    if current_user
      @transcription = Transcription.find(params[:id])
      @page = @transcription.page
      @user = current_user
    else
      flash[:danger] = 'Only users can transcribe documents! <a href="' + new_user_session_path + '">Log in to continue.</a>'
      redirect_to root_path
    end
  end

  # POST /transcriptions
  # POST /transcriptions.json
  def create
    if current_user
      
      Transcription.transaction do
        begin
          # @transcription is a variable containing an instance of the "transcription.rb" model 
          # created with data passed in the params of the "new.html.slim" form submit action.
          @transcription = nil
          @transcription = Transcription.create!(transcription_params)
          @transcription.page.transcriber_id = transcription_params[:user_id]
          @transcription.page.save!
        rescue => e
          flash[:danger] = e.message
        end
      end
      
      respond_to do |format|
        if @transcription && @transcription.id
          flash[:info] = 'You may now begin transcribing'
          format.html { redirect_to edit_transcription_url(@transcription) }
        else
          format.html { redirect_to transcribe_page_url(:current_page_id => params[:page_id]) }
        end
      end
      
    else
      flash[:danger] = 'Only users can create transcriptions! <a href="' + new_user_session_path + '">Log in to continue.</a>'
      redirect_to root_path
    end
  end

  # PUT /transcriptions/transcription_id
  # PUT /transcriptions/transcription_id.json
  def update
    if current_user
      
      Transcription.transaction do
        begin
          # @transcription is a variable containing an instance of the "transcription.rb" model 
          # with attributes updated with data passed in the params of the "edit.html.slim" form submit action. 
          transcription = Transcription.find(params[:id])
         
          transcription.update(transcription_params)
          flash[:success] = "Transcription sucessfully updated!"
        rescue => e
          flash[:danger] = e.message
        end
      end
      
      respond_to do |format|
        format.html { redirect_to transcriptions_url}
      end
      
    else
      flash[:danger] = 'Only users can modify transcriptions! <a href="' + new_user_session_path + '">Log in to continue.</a>'
      redirect_to root_path
    end
  end

  # DELETE /transcriptions/transcription_id
  # DELETE /transcriptions/transcription_id.json
  def destroy
    # this function is called to delete the instance of "transcription.rb" identified by 
    # the transcription_id passed to the destroy function when it was called
    if current_user && current_user.admin?
      
      Transcription.transaction do
        begin
          @transcription = Transcription.find(params[:id])
          @transcription.destroy
        rescue => e
          # flash[:danger] = e.message
        end
      end
      
      respond_to do |format|
        format.html { redirect_to transcriptions_url }
        format.json { head :no_content }
      end
      
    else
      redirect_to transcription_path(params[:id]), alert: 'Only administrators can delete transcriptions!'
    end
  end
  
  def get_or_assign_page(page_id) #TODO: shouldn't this be in the helper - file not the controller?
  # this function gets a random page for display on the new transcription page 
  # if one has not been set by selecting "Transcribe" on an page's show page
    if page_id
      @page = Page.find(page_id)
    else
      @page = Page.transcribeable.order("RAND()").first
    end
  end
  
  private
  def transcription_params
    params.require(:transcription).permit(:user_id, :page_id, :complete)
  end
end
