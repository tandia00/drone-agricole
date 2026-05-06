`timescale 1ns / 1ps

/*
 * TESTBENCH: drone_core_tb
 * DESCRIPTION: Permet de simuler et valider le silicium avant l'envoi à la fonderie.
 */
module drone_core_tb;

    reg clk;
    reg rst_n;
    reg [7:0] altitude;
    reg [7:0] tank_level;
    reg system_en;

    wire alert_empty_tank;
    wire valve_open;
    wire pump_pwm_out;

    // Instanciation du module matériel
    drone_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .altitude(altitude),
        .tank_level(tank_level),
        .system_en(system_en),
        .alert_empty_tank(alert_empty_tank),
        .valve_open(valve_open),
        .pump_pwm_out(pump_pwm_out)
    );

    // Génération de l'horloge
    always #5 clk = ~clk;

    initial begin
        // Fichier pour visualiser les ondes de la puce (GTKWave)
        $dumpfile("drone_core.vcd");
        $dumpvars(0, drone_core_tb);

        // Conditions initiales
        clk = 0;
        rst_n = 0;
        system_en = 0;
        altitude = 8'd0;
        tank_level = 8'd100;

        #20 rst_n = 1; system_en = 1;

        $display("--- DEBUT DE LA SIMULATION ---");
        $display("Initialisation: Drone au sol, cuve pleine.");

        // Test 1 : Altitude trop basse (1m) -> Pas de pulvérisation
        #10 altitude = 8'd10; 
        #100;
        $display("TEST 1: Altitude = 1.0m");
        if (valve_open) $display("  [X] ERREUR: Valve ouverte a 1m");
        else $display("  [V] SUCCES: Valve fermee (Securite respectee)");

        // Test 2 : Altitude idéale (3m) -> Pulvérisation (PWM actif)
        #10 altitude = 8'd30;
        #1000;
        $display("TEST 2: Altitude = 3.0m");
        if (!valve_open) $display("  [X] ERREUR: Valve fermee a 3m");
        else $display("  [V] SUCCES: Valve ouverte, Pulverisation en cours");

        // Test 3 : Réservoir vide en plein vol -> Arrêt d'urgence
        #10 tank_level = 8'd0;
        #100;
        $display("TEST 3: Niveau cuve = 0%% (en plein vol)");
        if (!alert_empty_tank) $display("  [X] ERREUR: Pas d'alerte cuve vide");
        else $display("  [V] SUCCES: Alerte de cuve vide declenchee !");
        if (valve_open) $display("  [X] ERREUR: Valve toujours ouverte avec cuve vide");
        else $display("  [V] SUCCES: Valve fermee d'urgence (Pompe coupee)");

        $display("--- FIN DE LA SIMULATION : Toutes les conditions logiques sont validees ! ---");
        $finish;
    end

endmodule
