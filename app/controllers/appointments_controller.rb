class AppointmentsController < ApplicationController

  class Slot

    def initialize(start_time, end_time, is_appointment, appointment_id, link)
      @start_time = start_time
      @end_time = end_time
      @is_appointment = is_appointment
      @appointment_id = appointment_id
      @link = link
    end

    def start_time
      @start_time
    end

    def end_time
      @end_time
    end

    def is_appointment
      @is_appointment
    end

    def appointment_id
      @appointment_id
    end

    def link
      @link
    end

  end

  class SlotListByDay

    def initialize(day, slot_list)
      @day = day
      @slot_list = slot_list
    end

    def day
      @day
    end

    def slot_list
      @slot_list
    end

  end

  def get_appointments

=begin
    for i in 1477..1489
      HTTParty.delete("https://appointment-ppr.sightcall.com/api/appointments/"+i.to_s,
        :headers => {"Content-Type": "application/vnd.api+json", "X-Authorization" => "Token Ua9vUzju3AahA19xuNYQftTAA4RM2XCy"},
        )
    end
=end

    # Récupération des données via l'API
    require 'json'
    require 'httparty'
    url = "https://appointment-ppr.sightcall.com/api/appointments"
    # response = RestClient.get url, {"Content-Type": "application/vnd.api+json", "X-Authorization" => "Token Ua9vUzju3AahA19xuNYQftTAA4RM2XCy"}
    response = HTTParty.get("https://appointment-ppr.sightcall.com/api/appointments",
      :headers => {"Content-Type": "application/vnd.api+json", "X-Authorization" => "Token Ua9vUzju3AahA19xuNYQftTAA4RM2XCy"},
      )
    
    hash_response = JSON.parse(response.body)
    result = hash_response['data']

    puts result

    # Initialisation de la liste des créneaux avec des rendez-vous déjà pris
    appointment_made_slot_list = Array.new

    # Construction de la liste des créneaux avec des rendez-vous déjà pris avec les données provenant de l'API
    result.each_with_index do |item, index|
      appointment_made_slot_list.push(
        Slot.new(
          Time.parse(item['attributes']['start-time']).getlocal('+02:00'), 
          Time.parse(item['attributes']['end-time']).getlocal('+02:00'), 
          true,
          item['id'],
          item['attributes']['agent-default-url']
        )
      )
      #puts "#{index + 1}: id #{item[:id]}, start-time #{item['attributes']['start-time']}"
    end

    # Nombre de jours qui viennent pour l'agent
    days_number = 3
    # Début de la journée
    start_time = 9
    # Fin de la journée
    end_time = 17
    # Temps d'un créneau
    slot_time = 30
    # Nombre de créneaux total par jour
    slots_per_day = (end_time - start_time) * (60 / slot_time)

    # Initialisation de la liste de tous les créneaux
    slot_list = Array.new

    # Initialisation de la variable créneau courante qui va servir à construire la liste de tous les créneaux
    current_slot_time = Time.now + 1.day
    current_slot_time = current_slot_time.change(hour: 9)

    # Construction de la liste de tous les créneaux
    # Parcours des jours
    for i in 0..days_number - 1
      
      slot_list_by_day = Array.new

      # Parcours des heures d'une journée
      for j in 0..slots_per_day - 1

        # Remplissage du de la liste avec le créneau courant
        slot_list_by_day.push(
          Slot.new(
            current_slot_time, 
            current_slot_time + slot_time.minute, 
            false,
            nil,
            nil
          )
        )

        # Parcours de la liste des créneaux avec des RDV déjà pris
        appointment_made_slot_list.each do |appointment|

          # Si le créneau courant n'est pas disponible 
          if appointment.start_time.strftime('%Y-%m-%d %H:%M:%S') == current_slot_time.strftime('%Y-%m-%d %H:%M:%S')

            # On remplace le dernier de la liste avec un créneau qui possède les informations du rendez-vous pris
            slot_list_by_day[-1] = appointment

          end

        end

        # Passage au créneau suivant de la journée
        current_slot_time = current_slot_time + slot_time.minute
        
      end

      slot_list.push(SlotListByDay.new(current_slot_time.strftime("%A %e %B"), slot_list_by_day))

      # Passage au début de la journée du jour suivant
      current_slot_time = current_slot_time + 1.day
      current_slot_time = current_slot_time.change(hour: start_time)

    end
    
    render template: "appointments/index", locals: { slot_list: slot_list }

  end

  def create_appointment

    agent_login = 'c.perrier13@laposte.net'
    
    response = HTTParty.post('https://appointment-ppr.sightcall.com/api/appointments', 
      :body => {
        'data' => {
          'type' => 'appointments',
          'attributes' => {
            'agent-login' => agent_login,
            'start-time' => params['start'],
            'end-time' => params['end'],
            'meeting-point' => true
          }
        }
      }.to_json,
      :headers => { 'Content-Type' => 'application/vnd.api+json', "X-Authorization" => "Token Ua9vUzju3AahA19xuNYQftTAA4RM2XCy"} )
      
      puts response

      render template: "appointments/create"

  end

  def cancel_appointment

    puts params['id'];

    response = HTTParty.delete("https://appointment-ppr.sightcall.com/api/appointments/"+params['id'],
      :headers => {"Content-Type": "application/vnd.api+json", "X-Authorization" => "Token Ua9vUzju3AahA19xuNYQftTAA4RM2XCy"},
      )

      puts response
      
      render template: "appointments/cancel"

  end

end
