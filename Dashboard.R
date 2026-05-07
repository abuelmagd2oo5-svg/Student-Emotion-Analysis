library(shiny)

# ================= DATA =================
doctors <- data.frame(
  id = "D1",
  username = "doctor1",
  password = "1234"
)

courses <- data.frame(
  course_id = "C1",
  course_name = "Linear Algebra",
  doctor_id = "D1"
)

schedule <- data.frame(
  course_id = c("C1","C1"),
  week = c(1,1),
  day = c("Sunday","Tuesday"),
  time = c("10:00","12:00")
)

# ================= UI (UNCHANGED) =================
ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("
      body {
        background-color: #0f172a;
        color: white;
        font-family: Arial;
      }

      .title {
        text-align: center;
        font-size: 32px;
        font-weight: bold;
        margin-top: 20px;
        color: #38bdf8;
      }

      .box {
        background-color: #1e293b;
        padding: 20px;
        border-radius: 15px;
        width: 60%;
        margin: auto;
        margin-top: 30px;
        box-shadow: 0px 0px 15px rgba(0,0,0,0.5);
        text-align: center;
      }

      img {
        display: block;
        margin-left: auto;
        margin-right: auto;
        width: 120px;
        border-radius: 10px;
      }

      select {
        width: 80%;
        padding: 8px;
        margin: 5px;
      }
      /* ===== Smooth Animations ===== */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}

.box {
  animation: fadeIn 0.6s ease-in-out;
}

/* ===== Buttons Animation ===== */
button {
  transition: all 0.25s ease-in-out;
  border-radius: 10px !important;
}

button:hover {
  transform: scale(1.05);
  box-shadow: 0px 8px 20px rgba(0,0,0,0.3);
}

/* ===== Sidebar Glow ===== */
.sidebar, .panel {
  transition: 0.3s;
}

.sidebar:hover {
  box-shadow: 0px 0px 25px rgba(56,189,248,0.3);
}

/* ===== Cards Upgrade ===== */
.card, .box {
  background: linear-gradient(145deg, #1e293b, #0f172a);
  box-shadow: 0px 6px 15px rgba(0,0,0,0.4);
}  
   
.sidebar {
  background:#1e293b;
  padding:20px;
  border-radius:15px;
  min-height:80vh;
  transition: 0.3s;
}

.sidebar:hover {
  transform: translateY(-3px);
  box-shadow: 0px 10px 25px rgba(0,0,0,0.4);
}

.card {
  background: #1f2937;
  padding: 20px;
  border-radius: 15px;
  border-left: 4px solid #38bdf8;
  transition: 0.3s;
}

.card:hover {
  transform: translateY(-3px);
  box-shadow: 0px 10px 25px rgba(0,0,0,0.4);
}
  
  "))
  ),
  
  div(class = "title", "AI Lecture Emotion System"),
  uiOutput("page")
)

# ================= SERVER =================
server <- function(input, output, session) {
  
  logged_in <- reactiveVal(FALSE)
  attempts <- reactiveVal(0)
  
  
  current_doctor <- reactiveVal(NULL)
  
  output$attendance_table <- renderTable({
    data.frame(
      ID = c("211014850", "231002467"),
      Name = c("Ahmed", "Ali"),
      Time = c("10:01", "10:03")
    )
  })
  time_slots <- data.frame(
    slot = 1:6,
    start = c("08:30","10:30","12:30","14:30","16:30","18:30"),
    end   = c("10:10","12:10","14:10","16:10","18:10","20:10")
  )
  
  lecture_schedule <- data.frame(
    course_id = character(),
    day = character(),
    slot = integer(),
    week = integer()
  )
  
  # ---------------- LOGIN UI ----------------
  login_page <- function() {
    
    div(
      style = "
      display:flex;
      justify-content:center;
      align-items:center;
      height:90vh;
    ",
      
      div(
        style = "
        background:#1e293b;
        padding:30px;
        border-radius:20px;
        width:350px;
        box-shadow:0px 0px 20px rgba(0,0,0,0.5);
        text-align:center;
      ",
        
        img(
          src = "https://cdn-icons-png.flaticon.com/512/4712/4712109.png",
          width = 100
        ),
        
        h3("Doctor Login", style="color:#38bdf8"),
        
        br(),
        
        textInput("username", NULL, placeholder = "Username"),
        passwordInput("password", NULL, placeholder = "Password"),
        
        br(),
        
        actionButton("login", "Login", 
                     style="width:100%; background:#38bdf8; color:black; font-weight:bold;"),
        
        br(), br(),
        
        uiOutput("result")
      )
    )
  }
  
  # ---------------- DASHBOARD ----------------
  dashboard_page <- function() {
    
    req(current_doctor())
    
    doc_id <- current_doctor()
    
    doc_courses <- courses[courses$doctor_id == doc_id, ]
    
    fluidRow(
      
      # ================= SIDEBAR =================
      column(
        3,
        div(class = "sidebar",
            
            h4("Doctor Panel", style="color:#38bdf8"),
            hr(),
            
            selectInput("course", "Course", choices = doc_courses$course_name),
            selectInput("week", "Week", choices = 1:15),
            
            br(),
            
            h5(tags$i(class="fa fa-cogs"), " Session Control"),
            actionButton(
              "open_schedule",
              label = NULL,
              icon = icon("calendar-days"),
              style="
              width:50px;
              height:50px;
              border-radius:50%;
              background:#38bdf8;
              color:black;
              border:none;
              margin-bottom:15px;
            "
            ),
            
            actionButton("start", "Start Lecture",
                         style="width:100%; margin-bottom:10px;"),
            
            actionButton("start_rec", "Start Recognition",
                         style="width:100%; margin-bottom:10px;"),
            
            actionButton("stop_rec", "Stop Recognition",
                         style="width:100%;"),
            
            br(), br(),
            
            tags$div("Status: READY", style="color:#22c55e; font-weight:bold;")
        )
      ),
      
      # ================= MAIN =================
      column(
        9,
        
        div(class="card",
            
            h3("Live Lecture Dashboard", style="color:#38bdf8"),
            
            uiOutput("schedule_panel"),
            
            br(),
            
            fluidRow(
              column(
                4,
                div(class="box", h5("Students Present"), h2("0"))
              ),
              column(
                4,
                div(class="box", h5("Active Emotion"), h2("-"))
              ),
              column(
                4,
                div(class="box", h5("Lecture Status"), h2("Stopped"))
              )
            ),
            
            br(),
            hr(),
            
            h4("Live Attendance"),
            
            tableOutput("attendance_table")
        )
      )
    )
  }
  
  # ---------------- SWITCH PAGE ----------------
  output$page <- renderUI({
    if (logged_in()) dashboard_page() else login_page()
  })
  
  # ---------------- LOGIN ----------------
  observeEvent(input$login, {
    
    row <- doctors[
      doctors$username == input$username &
        doctors$password == input$password, ]
    
    if (nrow(row) == 1) {
      
      logged_in(TRUE)
      current_doctor(row$id)
      
      attempts(0)
      
      output$result <- renderUI(h4("Login Success ✅"))
      
    } else {
      
      attempts(attempts() + 1)
      
      output$result <- renderUI(
        h4(paste("Wrong login - Attempts:", attempts()))
      )
      
      if (attempts() >= 3) {
        output$result <- renderUI(
          h3("Too many attempts... the password is hiding from you 😂")
        )
      }
    }
  })
  
  
  output$schedule_panel <- renderUI({
    
    if(input$open_schedule == 0) return(NULL)
    
    days <- c(
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday"
    )
    
    div(
      class = "card",
      
      h4("Weekly Schedule", style="color:#38bdf8;"),
      
      tags$table(
        
        style="
        width:100%;
        text-align:center;
        border-collapse:collapse;
      ",
        
        # ===== Header =====
        tags$tr(
          
          tags$th("Day"),
          
          lapply(1:6, function(i){
            
            tags$th(
              
              tags$div(
                paste("Session", i),
                
                tags$br(),
                
                paste(
                  time_slots$start[i],
                  "-",
                  time_slots$end[i]
                )
              ),
              
              style="
              padding:15px;
              background:#1e293b;
              border:1px solid #334155;
            "
            )
            
          })
        ),
        
        # ===== Rows =====
        lapply(days, function(day){
          
          tags$tr(
            
            tags$td(
              day,
              style="
              padding:15px;
              font-weight:bold;
              background:#1e293b;
              border:1px solid #334155;
            "
            ),
            
            lapply(1:6, function(i){
              
              tags$td(
                
                div(
                  style="
                  height:70px;
                  background:#0f172a;
                  border-radius:10px;
                ",
                  ""
                ),
                
                style="
                padding:10px;
                border:1px solid #334155;
              "
              )
              
            })
            
          )
          
        })
        
      )
    )
    
  })
  
  
  # ---------------- SCHEDULE ----------------
  output$schedule <- renderUI({
    
    req(input$course, input$week, current_doctor())
    
    doc_id <- current_doctor()
    
    course_id <- courses$course_id[
      courses$course_name == input$course &
        courses$doctor_id == doc_id
    ]
    
    sch <- schedule[
      schedule$course_id == course_id &
        schedule$week == as.numeric(input$week), ]
    
    if (nrow(sch) == 0) return(h5("No sessions"))
    
    tagList(
      lapply(1:nrow(sch), function(i) {
        tags$div(paste(sch$day[i], "-", sch$time[i]))
      })
    )
  })
}

shinyApp(ui, server)