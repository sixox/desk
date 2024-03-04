class LetterHeadsController < ApplicationController
	before_action :authenticate_user!

	def new	
		@letter_head = LetterHead.new
	end

	def create
		@letter_head = LetterHead.new(letter_head_params)
		respond_to do |format|
		  if @letter_head.save
		    format.html { redirect_back(fallback_location: root_path, notice: "File was successfully created.") }
		  else
		    format.html { redirect_back(fallback_location: root_path, alert: "File was not created.") }
		  end
		end
	end



	private

   

   

    def letter_head_params
      params.require(:letter_head).permit(:name, :file)
    end
end
