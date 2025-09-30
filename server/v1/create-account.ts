

/*

1. `id` should not already exist
2. insert into users (id, mobile, active, password) values (`id`, `id`, 1, '155$....')

supabase.from('users').insert({
    'id': id,
    'mobile': id,
    'active': 1,
    'password': '1111...'
})

*/
