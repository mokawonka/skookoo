# frozen_string_literal: true

class ClaimsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :require_user, only: [:show, :success]
  prepend_before_action :store_return_to_for_claim, only: [:create]

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
    agent.claim!(current_user)
    flash[:claimed_agent_name] = agent.name
    redirect_to claim_success_path
  end

  def success
    @agent_name = flash[:claimed_agent_name]
    redirect_to root_path, notice: "Agent claimed successfully." if @agent_name.blank?
  end

  private

  def store_return_to_for_claim
    return if logged_in?
    session[:return_to] = claim_path(params[:claim_token]) if params[:claim_token].present?
  end
end
