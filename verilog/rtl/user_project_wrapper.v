`default_nettype none

/*
 * MODULE: user_project_wrapper
 * DESCRIPTION: Le "Harnais" standard obligatoire pour la fonderie Efabless (Caravel SoC).
 * Ce fichier connecte notre logique (drone_core) aux broches physiques (Pads) de la puce.
 */

module user_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda1,  // Alimentation Analogique 1
    inout vdda2,  // Alimentation Analogique 2
    inout vssa1,  // Masse Analogique 1
    inout vssa2,  // Masse Analogique 2
    inout vccd1,  // Alimentation Numérique 1 (1.8V)
    inout vccd2,  // Alimentation Numérique 2 (1.8V)
    inout vssd1,  // Masse Numérique 1
    inout vssd2,  // Masse Numérique 2
`endif

    // Signaux de gestion de la puce (Wishbone Bus)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Analyseur logique (Pour débugger la puce une fois fabriquée)
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // Broches d'entrées/sorties physiques de la puce (GPIOs)
    input  [37:0] io_in,
    output [37:0] io_out,
    output [37:0] io_oeb,

    // Interruptions et Horloge utilisateur
    input   user_clock2,
    output [2:0] user_irq
);

    // Ignorer le bus système complexe pour ce projet, on garde cela simple.
    assign wbs_ack_o = 1'b0;
    assign wbs_dat_o = 32'b0;
    assign la_data_out = 128'b0;
    assign user_irq = 3'b0;

    // -------------------------------------------------------------------------
    // CÂBLAGE DE NOTRE DRONE_CORE VERS LES BROCHES PHYSIQUES DE LA PUCE
    // -------------------------------------------------------------------------

    wire alert_empty_tank;
    wire valve_open;
    wire pump_pwm_out;

    drone_core core_inst (
        .clk(wb_clk_i),                 // Horloge principale de la puce
        .rst_n(~wb_rst_i),              // Reset de la puce

        // On relie l'altitude aux broches physiques n°8 à 15 (8 bits)
        .altitude(io_in[15:8]),
        
        // On relie le niveau de cuve aux broches physiques n°16 à 23 (8 bits)
        .tank_level(io_in[23:16]),
        
        // Broche 24 pour activer tout le système matériel
        .system_en(io_in[24]),

        // Sorties
        .alert_empty_tank(alert_empty_tank),
        .valve_open(valve_open),
        .pump_pwm_out(pump_pwm_out)
    );

    // On relie nos signaux de contrôle aux broches de sortie 25, 26, et 27
    assign io_out[25] = alert_empty_tank;
    assign io_out[26] = valve_open;
    assign io_out[27] = pump_pwm_out;

    // Toutes les autres broches de sortie sont forcées à 0 par sécurité
    assign io_out[37:28] = 10'b0;
    assign io_out[24:0]  = 25'b0;

    // Configuration de la direction des broches (0 = Sortie, 1 = Entrée)
    // Seules les broches 25, 26 et 27 sont des sorties !
    assign io_oeb[25] = 1'b0;
    assign io_oeb[26] = 1'b0;
    assign io_oeb[27] = 1'b0;
    
    // Le reste en entrée (Haute impédance)
    assign io_oeb[37:28] = 10'h3FF;
    assign io_oeb[24:0]  = 25'h1FFFFFF;

endmodule
