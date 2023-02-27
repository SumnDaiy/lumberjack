Config = {}

Config.treeModel = `prop_tree_olive_01`
Config.stump = `prop_tree_stump_01`
Config.log = `prop_log_01`

Config.respawnTimer = 10000

Config.bossLocation = vec4(1200.505, -1276.669, 35.225, 351.426)
Config.trailerSpawnCoords = vec4(1207.345, -1229.944, 35.227, 271.916)

Config.target = true

Config.PriceMultiplier = 100 -- 1 log * 100 = 100$

Config.Locations = {
    {
    model = Config.treeModel,
    location = vec3(-728.488, 5401.086, 50.876),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-716.452, 5395.412, 53.958),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-711.504, 5388.111, 56.417),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-720.513, 5387.617, 55.978),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-734.543, 5386.100, 54.204),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-743.369, 5376.933, 55.414),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-731.026, 5368.666, 59.563),
    rotation = vec3(0,0,0)
    },
    {
    model = Config.treeModel,
    location = vec3(-718.712, 5363.774, 61.941),
    rotation = vec3(0,0,0)
    },
}

Config.AddBlip = true
Config.BlipSettings = {
    {
        coords = vec3(1200.505, -1276.669, 35.225),
        id = 77,
        display = 4,
        scale = 0.8,
        colour = 25,
        name = 'Lumberjack'
    },
    {
        coords = vec3(-725.893, 5376.885, 58.279),
        id = 210,
        display = 4,
        scale = 0.8,
        colour = 25,
        name = 'Forest'
    }

}