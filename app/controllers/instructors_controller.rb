class InstructorsController < ApplicationController

  # GET /instructors
  # GET /instructors.json
  def index
    # @instructors = Instructor.all
    redirect_to search_instructors_path
  end

  # GET /instructors/1
  # GET /instructors/1.json
  # def show
  # end

  # GET /instructors/new
  def new
    @instructor = Instructor.new
  end

  # GET /instructors/1/edit
  # def edit
  # end

  # POST /instructors
  # POST /instructors.json
  def create
    @instructor = Instructor.new(instructor_params)

    respond_to do |format|
      if @instructor.save
        format.html { redirect_to @instructor, notice: 'Instructor was successfully created.' }
        format.json { render :show, status: :created, location: @instructor }
      else
        format.html { render :new }
        format.json { render json: @instructor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /instructors/1
  # PATCH/PUT /instructors/1.json
  def update
    respond_to do |format|
      if @instructor.update(instructor_params)
        format.html { redirect_to @instructor, notice: 'Instructor was successfully updated.' }
        format.json { render :show, status: :ok, location: @instructor }
      else
        format.html { render :edit }
        format.json { render json: @instructor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /instructors/1
  # DELETE /instructors/1.json
  # def destroy
  #   @instructor.destroy
  #   respond_to do |format|
  #     format.html { redirect_to instructors_url, notice: 'Instructor was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  def search

    @search_suggestions = ["HUMA", "Cannon", "COCI", "4065"]

    if !params[:query].blank? && params[:query].length >= 3
      @instructors = Instructor.where('name ILIKE ? OR course ILIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
      @min_range_instructor = @instructors.order(:range).first
      @max_range_instructor = @instructors.order(:range).last
      @instructors_chart = @instructors.group(:range).count
      @instructors_avg = @instructors.average(:range).round(2)
    end
    # If all instructors have same uname, give a range on top of the table
    # @grouped_instructors = @instructors.group(:uname).count

    # End
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instructor
      @instructor = Instructor.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def instructor_params
      params.require(:instructor).permit(:name, :course, :range)
    end
end
