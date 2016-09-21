require 'net/http'
require 'json'

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

    if !params[:query].blank? && params[:query].length >= 3

      culpa_search_url_str = "http://api.culpa.info/professors/search/#{params[:query]}".gsub(/\s+/, "%20")
      culpa_search_url = URI.parse(culpa_search_url_str)
      culpa_search_req = Net::HTTP::Get.new(culpa_search_url.to_s)
      culpa_search_res = Net::HTTP.start(culpa_search_url.host, culpa_search_url.port) {|http|
        http.request(culpa_search_req)
      }
      culpa_search_response = JSON.parse(culpa_search_res.body)
      @culpa_search_profs = culpa_search_response["professors"].select do |prof|
        prof_uri = "http://api.culpa.info/reviews/professor_id/#{prof["id"]}"
        url = URI.parse(prof_uri)
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        JSON.parse(res.body)["reviews"].count > 0
      end

      if !params[:prof_id].blank?
        prof_uri = "http://api.culpa.info/reviews/professor_id/#{params[:prof_id]}"
        url = URI.parse(prof_uri)
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        if res.kind_of? Net::HTTPSuccess
          culpa_response = JSON.parse(res.body)
          @culpa_reviews = culpa_response["reviews"].map {|resp| resp["review_text"]}
          if @culpa_reviews.count > 0
            @payload = @culpa_reviews.to_json

            uri = URI('http://sentiment.vivekn.com/api/batch/')
            reqst = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
            reviews = @culpa_reviews.map {|r| r.to_json}
            reqst.body = reviews.to_json
            respnse = Net::HTTP.start(uri.hostname, uri.port) do |http|
              http.request(reqst)
            end
            parsed_respnse = JSON.parse(respnse.body)
            if !parsed_respnse.is_a?(Hash)
              pos_score = 0.0
              neg_score = 0.0

              parsed_respnse.each do |sentiment|
                if sentiment["result"] == "Positive"
                  pos_score += sentiment["confidence"].to_f
                elsif sentiment["result"] == "Negative"
                  neg_score += sentiment["confidence"].to_f
                end
              end

              pos_score /= 100
              neg_score /= 100

              @score = (pos_score - neg_score)/parsed_respnse.count

              if @score > 0
                @score_color = "green"
              elsif @score < 0
                @score_color = "red"
              else
                @score_color = ""
              end

              if @score > 0.4
                @score_text = "Really good"
              elsif @score > 0.2
                @score_text = "Mostly good"
              elsif @score > 0.03
                @score_text = "Neutral-Good"
              elsif @score <= 0.03 && @score >= -0.03
                @score_text = "Neutral-ish"
              elsif @score < 0.03
                @score_text = "Neutral-Bad"
              elsif @score < -0.2
                @score_text = "Mostly Bad"
              elsif @score < -0.4
                @score_text = "Very Bad"
              end
            end
          end
        end
      end

    end


    @search_suggestions = ["HUMA", "Cannon", "COCI", "4065"]

    if !params[:query].blank? && params[:query].length >= 3
      @instructors = Instructor.where('name ILIKE ? OR course ILIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
      if !@instructors.blank?
        @min_range_instructor = @instructors.order(:range).first
        @max_range_instructor = @instructors.order(:range).last
        @instructors_chart = @instructors.group(:range).count
        @instructors_avg = @instructors.average(:range).round(2)
      end
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
