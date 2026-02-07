# frozen_string_literal: true

class ClaimsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :require_user, only: [:show, :create]

  def show
    @agent = Agent.find_by(claim_token: params[:claim_token])
    unless @agent
      flash[:alert] = "Invalid or expired claim link."
      redirect_to root_path and return
    end
    if @agent.claimed?
      flash[:notice] = "This agent has already been claimed."
      redirect_to root_path and return
    end
  end

  def create
    agent = Agent.find_by(claim_token: params[:claim_token])
    unless agent
      flash[:alert] = "Invalid or expired claim token."
      redirect_to root_path and return
    end
    if agent.claimed?
      flash[:notice] = "This agent has already been claimed."
      redirect_to root_path and return
    end
    if agent.verification_code.to_s.downcase != params[:verification_code].to_s.strip.downcase
      flash[:alert] = "Invalid verification code."
      redirect_to claim_path(agent.claim_token) and return
    end
    agent.claim!
    flash[:notice] = "Agent claimed successfully. The bot can now use its API key."
    redirect_to root_path
  end
end
