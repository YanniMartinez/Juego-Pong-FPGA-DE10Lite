
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pong_graph is
   port(
      clk, reset: std_logic;
      btn: std_logic_vector(1 downto 0);
      pixel_x,pixel_y: in std_logic_vector(9 downto 0);
      gra_still: in std_logic;
      graph_on, hit, miss: out std_logic;
      rgb: out std_logic_vector(2 downto 0)
   );
end pong_graph;

architecture arch of pong_graph is
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
    --primera barra
   constant BAR1_X_L: integer:=32;
   constant BAR1_X_R: integer:=35;
   signal bar1_y_t, bar1_y_b: unsigned(9 downto 0);
   constant BAR1_Y_SIZE: integer:=72;
   signal bar1_y_reg, bar1_y_next: unsigned(9 downto 0);
   constant BAR1_V: integer:=4;
   --Segunda barra
   constant BAR_X_L: integer:=600;
   constant BAR_X_R: integer:=603;
   signal bar_y_t, bar_y_b: unsigned(9 downto 0);
   constant BAR_Y_SIZE: integer:=72;
   signal bar_y_reg, bar_y_next: unsigned(9 downto 0);
   constant BAR_V: integer:=4;
   --Pelota
   constant BALL_SIZE: integer:=8; -- 8
   signal ball_x_l, ball_x_r: unsigned(9 downto 0);
   signal ball_y_t, ball_y_b: unsigned(9 downto 0);
   signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
   signal ball_y_reg, ball_y_next: unsigned(9 downto 0);
   signal ball_vx_reg, ball_vx_next: unsigned(9 downto 0);
   signal ball_vy_reg, ball_vy_next: unsigned(9 downto 0);
   constant BALL_V_P: unsigned(9 downto 0)
            :=to_unsigned(2,10);
   constant BALL_V_N: unsigned(9 downto 0)
            :=unsigned(to_signed(-2,10));
   type rom_type is array (0 to 7) of
        std_logic_vector (7 downto 0);
   constant BALL_ROM: rom_type :=
   (
      "00111100", --   ****
      "01111110", --  ******
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "01111110", --  ******
      "00111100"  --   ****
   );
   signal rom_addr, rom_col: unsigned(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);
   signal rom_bit: std_logic;
   signal bar1_on,bar_on, sq_ball_on, rd_ball_on: std_logic;
   signal bar1_rgb,bar_rgb, ball_rgb:
          std_logic_vector(2 downto 0);
   signal refr_tick: std_logic;
begin
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         bar1_y_reg <= (OTHERS=>'0');
			bar_y_reg <= (OTHERS=>'0');
         ball_x_reg <= (OTHERS=>'0');
         ball_y_reg <= (OTHERS=>'0');
         ball_vx_reg <= ("0000000100");
         ball_vy_reg <= ("0000000100");
			
      elsif (clk'event and clk='1') then
         bar1_y_reg <= bar_y_next;
			bar_y_reg <= bar1_y_next;
         ball_x_reg <= ball_x_next;
         ball_y_reg <= ball_y_next;
         ball_vx_reg <= ball_vx_next;
         ball_vy_reg <= ball_vy_next;
      end if;
   end process;
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
   
   -- barra1
   bar1_y_t <= bar1_y_reg;
   bar1_y_b <= bar1_y_t + BAR1_Y_SIZE - 1;
   bar1_on <=
      '1' when (BAR1_X_L<=pix_x) and (pix_x<=BAR1_X_R) and
               (bar1_y_t<=pix_y) and (pix_y<=bar1_y_b) else
      '0';
   bar1_rgb <= "010"; --verde
   -- barra2
   bar_y_t <= bar_y_reg;
   bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
   bar_on <=
      '1' when (BAR_X_L<=pix_x) and (pix_x<=BAR_X_R) and
               (bar_y_t<=pix_y) and (pix_y<=bar_y_b) else
      '0';
   bar_rgb <= "010"; --verde
   -- nueva posicion en y de la barra 1
   process(bar1_y_reg,bar1_y_b,bar1_y_t,refr_tick,btn,gra_still)
   begin
      bar1_y_next <= bar1_y_reg; -- no hay movimiento
      if gra_still='1' then  -- posicion inicial de la barra
         bar1_y_next <= to_unsigned((MAX_Y-BAR1_Y_SIZE)/2,10);
      elsif refr_tick='1' then
         if btn(1)='1' and bar1_y_b<(MAX_Y-1-BAR1_V) then
            bar1_y_next <= bar1_y_reg + BAR1_V; -- mover abajo
         elsif btn(0)='1' and bar1_y_t > BAR1_V then
            bar1_y_next <= bar1_y_reg - BAR1_V; -- mover arriba
         end if;
      end if;
   end process;
   -- nueva posicion en y de la barra 2
   process(bar_y_reg,bar_y_b,bar_y_t,refr_tick,btn,gra_still)
   begin
      bar_y_next <= bar_y_reg; -- no hay movimiento
      if gra_still='1' then  -- posicion inicial de la barra
         bar_y_next <= to_unsigned((MAX_Y-BAR_Y_SIZE)/2,10);
      elsif refr_tick='1' then
         if btn(1)='1' and bar_y_b<(MAX_Y-1-BAR_V) then
            bar_y_next <= bar_y_reg + BAR_V; -- mover abajo
         elsif btn(0)='1' and bar_y_t > BAR_V then
            bar_y_next <= bar_y_reg - BAR_V; -- mover arriba
         end if;
      end if;
   end process;
   -- pelota cuadrada
   ball_x_l <= ball_x_reg;
   ball_y_t <= ball_y_reg;
   ball_x_r <= ball_x_l + BALL_SIZE - 1;
   ball_y_b <= ball_y_t + BALL_SIZE - 1;
   sq_ball_on <=
      '1' when (ball_x_l<=pix_x) and (pix_x<=ball_x_r) and
               (ball_y_t<=pix_y) and (pix_y<=ball_y_b) else
      '0';
   -- pelota redonda
   rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
   rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
   rom_data <= BALL_ROM(to_integer(rom_addr));
   rom_bit <= rom_data(to_integer(not rom_col));
   rd_ball_on <=
      '1' when (sq_ball_on='1') and (rom_bit='1') else
      '0';
   ball_rgb <= "100";   -- rojo
   -- nueva posicion de la pelota
   ball_x_next <=
      to_unsigned((MAX_X)/2,10) when gra_still='1' else
      ball_x_reg + ball_vx_reg when refr_tick='1' else
      ball_x_reg ;
   ball_y_next <=
      to_unsigned((MAX_Y)/2,10) when gra_still='1' else
      ball_y_reg + ball_vy_reg when refr_tick='1' else
      ball_y_reg ;
   -- nueva velocidad de la pelota
   -- con un las señales de hit y miss
   process(ball_vx_reg,ball_vy_reg,ball_y_t,ball_x_l,ball_x_r,
           ball_y_t,ball_y_b,bar_y_t,bar_y_b,gra_still)
   begin
      hit <='0';
      miss <='0';
      ball_vx_next <= ball_vx_reg;
      ball_vy_next <= ball_vy_reg;
      if gra_still='1' then            --velocidad inicial
         ball_vx_next <= BALL_V_N;
         ball_vy_next <= BALL_V_P;
      elsif ball_y_t < 1 then          -- alcanza el tope
         ball_vy_next <= BALL_V_P;
      elsif ball_y_b > (MAX_Y-1) then  -- alcanza el fondo
         ball_vy_next <= BALL_V_N;
         --Barra1 
      elsif (BAR1_X_L<=ball_x_r) and (ball_x_r<=BAR1_X_R) and
            (bar1_y_t<=ball_y_b) and (ball_y_t<=bar1_y_b) then
            -- alcanza la posicion x de la barra, es un hit
            ball_vx_next <= BALL_V_P; -- rebote de regreso
            --hit <= '1';
            --Barra2
      elsif (BAR_X_L<=ball_x_r) and (ball_x_r<=BAR_X_R) and
            (bar_y_t<=ball_y_b) and (ball_y_t<=bar_y_b) then
            -- alcanza la posicion x de la barra, es un hit
            ball_vx_next <= BALL_V_N; -- rebote de regreso
            hit <= '1';
      elsif (ball_x_r>MAX_X) then     -- alcanza el borde derecho
         miss <= '1';                 -- un miss
		elsif (ball_x_r<25) then     -- alcanza el borde derecho
		miss <= '1';                 -- un miss
      end if;
   end process;
   -- circuito de multiplexeo de rgb 
   process(bar1_on,bar_on,rd_ball_on,bar1_rgb,bar_rgb,ball_rgb)
   begin
      if bar1_on='1' then
         rgb <= bar1_rgb;
      elsif bar_on='1' then
         rgb <= bar_rgb;
      elsif rd_ball_on='1' then
         rgb <= ball_rgb;
      else
         rgb <= "110"; -- fondo amarillo
      end if;
   end process;
   -- señal de nueva grafica activada
   graph_on <= bar1_on or bar_on or rd_ball_on;
end arch;
